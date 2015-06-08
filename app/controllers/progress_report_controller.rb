class ProgressReportController < ApplicationController
  unloadable
  
  before_filter :find_project, :authorize
  before_filter :find_version, :only => [:index, :generate]
  
  include ToceaCustomFieldsHelper
  
  require File.dirname(__FILE__) + '/../../../../app/helpers/issues_helper'
  ProgressReportController.send :include, IssuesHelper
  helper_method :show_detail
  include ERB::Util
  include ActionView::Helpers::TagHelper

  def index
      
    @date_from = params[:date_from] ? params[:date_from].to_date : nil

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
    ProgressReportExport.new(@report).export(report_content)
    
  end
  
  # static html page
  def empty
    
  end
  
  def last_report
    
    @version = params[:version_id] ? Version.where(name: params[:version_id]).first : nil
    
    date_from = Date.today
    date_from = Chronic.parse('monday', :context => :past) unless date_from.monday?
    
    @report = ProgressReportBuilder.new(@version ? @version : @project).from(date_from).build
    
    @attachment = ProgressReportExport.new(@report).last_report

    if @attachment.blank?
      redirect_to :controller => 'progress_report', :action => 'index', :project_id => @project.id
      return
    end
    
    redirect_to :controller => 'attachments', :action => 'download', :id => @attachment.id
    
  end
  
  private # ------------------------------------------------------------------------------------
  
  def find_project
    
    # retrieve the project
    @project = Project.find(params[:project_id])
    
  end
  
  # retrieve the version
  def find_version
    
    @version = nil
    version_id = params[:version_id]
    
    if !version_id.blank? && version_id != '0'    
      @version = Version.find(version_id)
    end

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
  
  def server_path
    
    if Setting.host_name
      path = 'http://'+Setting.host_name
    else
      path = request.base_url
    end
    
    path
  end
  
  # get the content of the report as an HTML string
  def report_content
    
    html = '<html>'
    html += '<head>'
    html += '<meta charset="utf-8" />'
    html += '<link href="'+server_path+'/themes/gitmike/stylesheets/application.css" media="all" rel="stylesheet" type="text/css" />'
    html += '<link href="'+server_path+'/plugin_assets/redmine_audit_assistant/stylesheets/audit_assistant.css" media="screen" rel="stylesheet" type="text/css" />'
    html += '</head>'
    html += render_to_string "progress_report/generate", :layout => false
    html += '</html>'
    
  end
  
end
