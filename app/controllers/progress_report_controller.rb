class ProgressReportController < ApplicationController
  unloadable
  
  before_filter :find_project, :authorize
  
  include ToceaCustomFieldsHelper
  
  def index
      
    @date_from = params[:date_from] ? params[:date_from].to_date : nil
        
    @version = get_version(params[:version_id])

    report = create_report(@project, @version, @date_from, @date_to)
    
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
       
    report = create_report(@project, @version, @date_from, @date_to, {
      :occupation_persons => format_occupation_persons_map(params[:member_occupation]),
      :time_switching_issues => params[:time_switching_issues]
    })
    
    # get report's data
    @issues = report.issues
    @date_beggining = report.date_beginning
    @date_effective = report.date_effective    
    @date_estimated = report.date_estimated   
    @effective_charge = report.charge_effective 'd'
    @estimated_charge = report.charge_estimated 'd'
    @left_charge = report.charge_left 'd'
    @is_late = report.late?
    @initial_charge = report.charge_initial 'd'
    @unassigned_charge = report.charge_unassigned 'd'
    
    # get project or version code    
    @code_project = @version.nil? ? code_project(@project) : code_version(@version)
    
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
  
  private # ------------------------------------------------------------------------------------
  
  def find_project
    
    # retrieve the project
    @project = Project.find(params[:project_id])
    
  end
  
  # format the hashmap that represent the percentage of occupation per person
  # it should not contains string and each value should be strictly greater than 0
  def format_occupation_persons_map(occupation_persons)
    res = Hash.new
    if occupation_persons
      res = Hash[occupation_persons.keys.map(&:to_i).zip(occupation_persons.values.map(&:to_i))]
    end
    res.select { |k,v| v.is_a?(Numeric) && v > 0 }
  end
  
  # create a ProgressReport instance
  def create_report(project, version, date_from, date_to, params={})
    
    report = nil
    
    if version
      report = ProjectVersionProgressReport.new(version, date_from, date_to, params)
    else
      report = ProjectProgressReport.new(project, date_from, date_to, params)
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
  
end
