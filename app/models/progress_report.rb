class ProgressReport
  
  attr_reader :root, :period, :data, :time_formatter
  
  def initialize(root, period, params={})
    
    @root = root    
    @period = period
    @period.date_from = date_beginning if @period.date_from.nil?
    @period.to_end_of_week if @period.date_to.nil?
    @time_formatter = TimeFormatter.new(@@nb_hours_per_day)
    params[:time_formatter] = @time_formatter
    @data = ProgressReportData.new(self, params)
    
  end
  
  @@nb_hours_per_day = 8.00
  
  # Helpers
  include ProgressReportHelper
  include ToceaCustomFieldsHelper
  
  # abstract method
  def project
    nil
  end
  
  # abstract method
  def version
    nil
  end
  
  # abstract method
  def issues
    raise NotImplementedError
  end
  
  # retrieve the list of users that are assigned to issues
  def users
    issues.map { |issue| issue.assigned_to }.uniq.compact
  end
  
  # retrieve the date when the project started
  def date_beginning
    issues.map {|issue| issue.created_on }.min
  end
  
  # retrieve the date where the project is supposed to end
  def date_effective
    issues.map { |issue| issue.due_date }.max
  end
  
  # get an estimation of the date when the project will be completed
  def date_estimated   
    
    DateEstimationStrategy.new(self).calculate
    
  end
  
  # check if the project will be late
  def late?
    
    estimated = date_estimated
    effective = date_effective  
    
    # the project cannot be late if we don't know the effective date
    return false if effective.nil?
    
    if !estimated
      # if we don't have an estimated date
      # the project is not late only if the effective date hasn't been reached yet
      return Date.today > effective.to_date
    end
    
    return estimated.to_date > effective.to_date
    
  end
  
  # return the list of issues that has been updated during a given period
  def issues_updated
    
    issues_list = issues
    
    journals = get_issues_journals(issues_list, @period.date_from, @period.date_to)
    
    issues_ids_changed = journals.map { |j| j.journalized_id }
    
    issues_list.select { |issue| issues_ids_changed.include?(issue.id) }
    
  end
  
  # return the changes of the issues during the report's period
  def issue_changelog(issue)
     
    if !@changelog
      journals = get_issues_journals(issues, @period.date_from, @period.date_to)
      @changelog = get_journal_details(journals)
    end
    
    @changelog.select { |change| change.journal.journalized_id == issue.id } 
    
  end
  
  # total initial charge (abstract method)
  def charge_initial(format='h')
    
    @time_formatter.format_hours(0.00, format)
    
  end
  
  # total estimated_hours of every issue
  def charge_effective(format='h')
     
    total = leaf_issues.map { |issue| issue.estimated_hours ? issue.estimated_hours : 0 }.reduce(:+) 

    @time_formatter.format_hours(total, format)
     
  end
  
  # total estimated hours of every issue 
  # with taking into consideration the % occupation per person
  def charge_estimated(format='h')
    
    total = 0
    list_issues = leaf_issues
    
    list_issues.each do |issue|
      if issue.estimated_hours
        total += issue.estimated_hours / data.person_occupation_rate(issue.assigned_to_id)
      end
    end
    
    total += data.total_time_before_starting
    total += data.total_time_switching_issues(list_issues)
 
    @time_formatter.format_hours(total, format)
    
  end
  
  # total charge that is not affected to anybody
  def charge_unassigned(format='h')
    
    total = 0
    leaf_issues.each do |issue|
      if issue.assigned_to_id.nil? && !issue.estimated_hours.nil?
        total += issue.estimated_hours
      end
    end
    @time_formatter.format_hours(total, format)
    
  end
  
  # total charge left at the end of period
  def charge_left(format='h')
        
    total = charge_initial
    total = charge_effective if total.nil? || total == 0
    
    leaf_issues.each do |issue|
      if issue.estimated_hours    
        total -= issue.estimated_hours * issue_done_ratio(issue)
      end
    end
    
    @time_formatter.format_hours(total, format)
    
  end
  
  # return the time progression in percentage
  def time_progression
    
    if Date.today > @period.date_to.to_date
      actual_date = @period.date_to
    else  
      actual_date = Date.today
    end
    
    date_end = date_effective
    date_end = date_estimated if date_end.nil?
    
    date_start = date_beginning.to_date
    
    burnt = actual_date.to_date - date_start.to_date
    total = date_end.to_date - date_start.to_date
    
    ratio = total > 0 ? (burnt / total) * 100 : 0

    ratio.to_i
    
  end
  
  # return the percentage value of the charge progression
  def charge_progression
    
    total = charge_initial
    total = charge_effective if total == 0
    
    done = total - charge_left  
    
    ratio = total > 0 ? (done.to_f / total.to_f) * 100 : 0
    
    ratio.to_i
    
  end
  
  # return the list of issues which don't have child issues
  def leaf_issues
    issues.select { |issue| leaf? issue }   
  end
  
  def leaf?(issue)
    
    childs = Issue.where(parent_id: issue.id)  
    childs.blank?

  end
  
  def issue_todo_ratio(issue)
    
    1 - issue_done_ratio(issue)
    
  end
  
  def issue_done_ratio(issue)
    
    return 1 if issue.closed?
    
    done_ratio = issue.done_ratio ? issue.done_ratio : 0.00
    
    done_ratio / 100.00
    
  end
  
end