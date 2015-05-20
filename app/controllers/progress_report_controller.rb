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
    
    @periods = Array.new
    
    date_from = Chronic.parse('monday', :context => :past)
    date_to = Chronic.parse('friday')
    
    @date_beggining_project = issues_project.map {|issue| issue.created_on }.min
    
    while date_to >= @date_beggining_project do
      
      date_lib = date_from.strftime("%d/%m/%y") + ' - ' + date_to.strftime("%d/%m/%y")
      @periods.push([date_lib, date_from])
      
      date_from = Chronic.parse('last monday', :now => date_from)
      date_to = Chronic.parse('last friday', :now => date_to)
      
    end
    
    @select_versions = []
    @versions = @project.shared_versions.open
    @versions.each do |v|
      @select_versions.push([v.name, v.id])
    end
    
  end

  def generate
    
    # retrieve the project
    @project = Project.find(params[:project_id])
    
    # retrieve the version
    version_id = params[:version_id]
    if (version_id && version_id != '0')
      @version = Version.find(version_id)
    end
    
    # retrieve the issues
    @issues = Issue.where(fixed_version_id: @version.id)
    
    # retrieve the dates
    @date_from = params[:period].to_date
    @date_to = Chronic.parse('next friday', :now => @date_from) 
    
    @date_beggining = @issues.map {|issue| issue.created_on }.min
    @date_effective = @version.effective_date
    @date_estimated = Time.now
    
    @effective_charge = 0
    @estimated_charge = 0
    @left_charge = 0
    
    # get the list of the issues that has been updated during the period
    @issues_updated = issues_updated(@issues, @date_from, @date_to)
    puts "what changed?"
    puts @issues_updated.map { |issue| issue.id }
    
    # restore the issues to their states at the end of the period
    @issues_updated = @issues_updated.map { |issue| restore_issue_state(issue, @date_from, @date_to) }
    
    # get the list of the issues that will be done this week
    issues_ids = params[:issues_ids] ? params[:issues_ids] : []
    @issues_next = @issues.select { |issue| issues_ids.include? issue.id.to_s }

    # get the comment
    @what_went_wrong = params[:what_went_wrong] ? params[:what_went_wrong] : ''

  end
  
end
