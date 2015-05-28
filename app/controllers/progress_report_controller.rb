class ProgressReportController < ApplicationController
  unloadable
  
  before_filter :find_project, :authorize
  
  def index
      
    @date_from = params[:date_from] ? params[:date_from].to_date : nil
        
    @version = get_version(params[:version_id])

    report = create_report(@project, @version, @date_from, @date_to, nil)
    
    if report.date_beginning.nil?
      redirect_to :controller => 'progress_report', :action => 'empty', :project_id => @project.id
      return
    end
    
    @periods = Array.new
    
    report.get_week_periods.each do |p|
      date_lib = p[0].strftime("%d/%m/%y") + ' - ' + p[1].strftime("%d/%m/%y")
      @periods.push([date_lib, p[0].strftime('%F')])
    end
    
    @issues = report.issues.reject { |issue| issue.status.is_closed? }
    
    @users = report.users
        
    @date_beggining_project = report.date_beginning

    @select_versions = get_versions_list(@project)
    
  end

  def generate   
    
    # retrieve the dates
    @date_from = params[:period].to_date
    @date_to = Chronic.parse('next friday', :now => @date_from)   
    
    @version = get_version(params[:version_id])
    
    @occupation_persons = params[:member_occupation] ? params[:member_occupation] : nil
       
    report = create_report(@project, @version, @date_from, @date_to, @occupation_persons)
    
    # get report's data
    @issues = report.issues
    @date_beggining = report.date_beginning
    @date_effective = report.date_effective    
    @date_estimated = report.date_estimated   
    @effective_charge = report.charge_effective 'd'
    @estimated_charge = report.charge_estimated 'd'
    @left_charge = report.charge_left 'd'
    
    # get the list of the issues that has been updated during the period
    @issues_updated = report.issues_updated
    
    # get the list of the issues that will be done this week
    issues_ids = params[:issues_ids] ? params[:issues_ids] : []
    @issues_next = @issues.select { |issue| issues_ids.include? issue.id.to_s }

    # get the comment
    @what_went_wrong = params[:what_went_wrong] ? params[:what_went_wrong] : ''

  end
  
  def empty
    
  end
  
  private # ---------------------------------------------------------------------------
  
  def find_project
    
    # retrieve the project
    @project = Project.find(params[:project_id])
    
  end
  
  def create_report(project, version, date_from, date_to, occupation_persons)
    
    report = nil
    
    if version
      report = ProjectVersionProgressReport.new(version, date_from, date_to, occupation_persons)
    else
      report = ProjectProgressReport.new(project, date_from, date_to, occupation_persons)
    end
    
    report
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
      select_versions.push([v.name, v.id]) unless v.closed?
    end
    
    select_versions
  end
  
end
