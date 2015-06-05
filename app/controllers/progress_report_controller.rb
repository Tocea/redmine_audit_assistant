class ProgressReportController < ApplicationController
  unloadable
  
  before_filter :find_project, :authorize
  
  include ToceaCustomFieldsHelper
  
  require File.dirname(__FILE__) + '/../../../../app/helpers/issues_helper'
  ProgressReportController.send :include, IssuesHelper
  helper_method :show_detail
  include ERB::Util
  include ActionView::Helpers::TagHelper
  
  def index
      
    @date_from = params[:date_from] ? params[:date_from].to_date : nil
        
    @version = get_version(params[:version_id])

    report = ProgressReportBuilder.new(@version ? @version : @project).from(@date_from).to(@date_to).build
    
    @date_beggining_project = report.date_beginning
    
    if @date_beggining_project.nil?
      redirect_to :controller => 'progress_report', :action => 'empty', :project_id => @project.id
      return
    end

    @issues = report.issues.reject { |issue| issue.status.is_closed? }   
    @users = report.users

    @select_versions = get_versions_list(@project)
    @periods = get_week_periods(@date_beggining_project)
    
  end

  def generate   
    
    # retrieve the dates
    @date_from = params[:period].to_date
    @date_to = Chronic.parse('next friday', :now => @date_from)   
    
    @version = get_version(params[:version_id])

    @report = ProgressReportBuilder
                .new(@version ? @version : @project)
                .from(@date_from)
                .to(@date_to)
                .with({
                  :occupation_persons => params[:member_occupation],
                  :time_switching_issues => params[:time_switching_issues],
                  :days_off => params[:days_off],
                  :start_time => params[:start_time]
                }).build
    
    # get report's data
    @issues = @report.issues
    @date_beggining = @report.date_beginning
    @date_effective = @report.date_effective    
    @date_estimated = @report.date_estimated   
    @effective_charge = @report.charge_effective 'd'
    @estimated_charge = @report.charge_estimated 'd'
    @left_charge = @report.charge_left 'd'
    @is_late = @report.late?
    @initial_charge = @report.charge_initial 'd'
    @unassigned_charge = @report.charge_unassigned 'd'
    @time_progression = @report.time_progression
    @charge_progression = @report.charge_progression
    
    # get project or version code    
    @code_project = @version.nil? ? code_project(@project) : code_version(@version)
    
    # get the list of the issues that has been updated during the period
    @issues_updated = @report.issues_updated
    
    # get the list of the issues that will be done this week
    issues_ids = params[:issues_ids] ? params[:issues_ids] : []
    @issues_next = @issues.select { |issue| issues_ids.include? issue.id.to_s }

    # get the comment
    @what_went_wrong = params[:what_went_wrong] ? params[:what_went_wrong] : ''

    # save the progress report
    save_report
    
  end
  
  # static html page
  def empty
    
  end
  
  def last_report
    
    @version = params[:version_id] ? Version.where(name: params[:version_id]).first : nil
    
    attachments = Attachment.where(
          container_type: 'Project', 
          container_id: @project.id, 
          filename: report_filename
    ).order('created_on DESC')
    
    if attachments.blank?
      redirect_to :controller => 'progress_report', :action => 'index', :project_id => @project.id
      return
    end
    
    redirect_to :controller => 'attachments', :action => 'download', :id => attachments[0].id
    
  end
  
  private # ------------------------------------------------------------------------------------
  
  def find_project
    
    # retrieve the project
    @project = Project.find(params[:project_id])
    
  end
  
  # retrieve the version
  def get_version(version_id)
    
    version = nil
    if !version_id.blank? && version_id != '0'    
      version = Version.find(version_id)
    end
    
    version
  end
  
  # retrieve the list of all open (or locked) versions of a project
  def get_versions_list(project)
    
    select_versions = [['root', 0]]
    versions = Version.where(project_id: project.id)
    versions.each do |v|
      select_versions.push([v.name, v.id])
    end
    
    select_versions
  end
  
  # retrieve the list of weeks since the beggining of the project
  def get_week_periods(min_date)
    
    periods = Array.new
    week_periods = PeriodProgressReport.week_periods(min_date)
    
    week_periods.each do |p|
      date_lib = p.date_from.strftime("%d/%m/%y") + ' - ' + p.date_to.strftime("%d/%m/%y")
      periods.push([date_lib, p.date_from.strftime('%F')])
    end
    
    periods
  end
  
  # get the name of the generated file that contains the report
  def report_filename
    
    filename = 'Report'
    filename += ' - '+@version.name if @version
    filename += '.html' 
    
    filename
  end
  
  # get the content of the report as an HTML string
  def report_content
    
    html = '<html>'
    html += '<head>'
    html += '<meta charset="utf-8" />'
    html += '<link href="'+request.base_url+'/themes/gitmike/stylesheets/application.css" media="all" rel="stylesheet" type="text/css" />'
    html += '</head>'
    html += render_to_string "progress_report/generate", :layout => false
    html += '</html>'
    
    html.gsub("/plugin_assets/", request.base_url+"/plugin_assets/")
    
  end
  
  # save the generated progress report
  def save_report
    
    filename = report_filename 
    
    html = report_content
    
    File.open(filename, 'w:UTF-8') do |f|
      f.puts html.encode('utf-8')
    end
    
    attachment = Attachment.new(:file => File.open(filename, 'r:UTF-8'))
    attachment.author = User.current
    attachment.filename = filename
    attachment.container = @project
    attachment.save
    
  end
  
end
