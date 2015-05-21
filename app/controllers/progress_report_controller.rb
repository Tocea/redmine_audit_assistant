class ProgressReportController < ApplicationController
  unloadable
  
  helper :progress_report
  include ProgressReportHelper
  
  def index
    
    @project = Project.find(params[:project_id])
    
    issues_project = Issue.where(project_id: @project.id)
    @issues = Array.new
    
    issues_project.each do |issue|
      @issues.push(issue) #unless issue.status.is_closed?
    end
    
    @users = @issues.map { |issue| issue.assigned_to }.uniq
        
    @date_beggining_project = issues_project.map {|issue| issue.created_on }.min
    
    @periods = get_week_periods(@date_beggining_project)   
    
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
    
    if !params[:version_id].blank? && params[:version_id] != '0'
      # retrieve the version
      version_id = params[:version_id]
      @version = Version.find(version_id)
    end
    
    @occupation_persons = params[:member_occupation] ? params[:member_occupation] : nil
    
    report = nil
    
    if @version
      report = ProjectVersionProgressReport.new(@version, @date_from, @date_to, @occupation_persons)
    else
      report = ProjectProgressReport.new(@project, @date_from, @date_to, @occupation_persons)
    end
    
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
  
  def get_week_periods(date_beggining_project)
    
    periods = Array.new
    
    date_from = Chronic.parse('monday', :context => :past)
    date_to = Chronic.parse('friday')
    
    while date_to >= date_beggining_project do
      
      date_lib = date_from.strftime("%d/%m/%y") + ' - ' + date_to.strftime("%d/%m/%y")
      periods.push([date_lib, date_from])
      
      date_from = Chronic.parse('last monday', :now => date_from)
      date_to = Chronic.parse('last friday', :now => date_to)
      
    end
    
    periods
    
  end
  
end
