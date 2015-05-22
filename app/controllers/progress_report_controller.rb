class ProgressReportController < ApplicationController
  unloadable
  
  helper :progress_report
  include ProgressReportHelper
  
  def index
    
    @project = Project.find(params[:project_id])
      
    @date_from = params[:date_from] ? params[:date_from].to_date : nil
        
    @version = get_version(params[:version_id])

    report = create_report(@project, @version, @date_from, @date_to, nil)
    
    @periods = Array.new
    
    report.get_week_periods.each do |p|
      date_lib = p[0].strftime("%d/%m/%y") + ' - ' + p[1].strftime("%d/%m/%y")
      @periods.push([date_lib, p[0].strftime('%F')])
    end
    
    @issues = report.issues.reject { |issue| issue.status.is_closed? }
    
    @users = @issues.map { |issue| issue.assigned_to }.uniq
        
    @date_beggining_project = report.date_beginning

    @select_versions = [['root', 0]]
    @versions = @project.shared_versions.open
    @versions.each do |v|
      @select_versions.push([v.name, v.id])
    end
    
  end

  def generate
    
    # retrieve the project
    @project = Project.find(params[:project_id])
    
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
  
  private # ---------------------------------------------------------------------------
  
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
  
end
