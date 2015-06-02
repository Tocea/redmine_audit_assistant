class ProgressReport
  
  attr_reader :root, :period, :occupation_persons, :time_switching_issues
  
  def initialize(root, date_from, date_to, params={})
    
    @root = root    
    @occupation_persons = format_occupation_persons_map(params[:occupation_persons])
    @time_switching_issues = params[:time_switching_issues].to_f
    @period = PeriodProgressReport.new(date_from ? date_from : date_beginning, date_to) 
    if !date_to
      @period.to_end_of_week
    end
    
  end
  
  @@nb_hours_per_day = 8.00
  
  # Helpers
  include ProgressReportHelper
  include ToceaCustomFieldsHelper
  
  # abstract method
  def issues
    raise NotImplementedError
  end
  
  def users
    issues.map { |issue| issue.assigned_to }.uniq.compact
  end
  
  def date_beginning
    issues.map {|issue| issue.created_on }.min
  end
  
  def date_effective
    issues.map { |issue| issue.due_date }.max
  end
  
  # get an estimation of the date when the project will be completed
  def date_estimated   
    
    # get the estimated date of the end of every person's work
    dates = users.map { |user| date_estimated_for(user) }
    
    # add the estimated date of the work not assigned to anybody
    dates.push(date_estimated_for(nil))
    
    # take the maximum date
    dates.max
    
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
  
  # total initial charge (abstract method)
  def charge_initial(format='h')
    
    format_hours(0.00, format)
    
  end
  
  # total estimated_hours of every issue
  def charge_effective(format='h')
     
    total = leaf_issues.map { |issue| issue.estimated_hours ? issue.estimated_hours : 0 }.reduce(:+) 
     
    format_hours(total, format)
     
  end
  
  # total estimated hours of every issue 
  # with taking into consideration the % occupation per person
  def charge_estimated(format='h')
    
    total = 0
    list_issues = leaf_issues
    
    list_issues.each do |issue|
      if issue.estimated_hours
        tx = 1
        if @occupation_persons[issue.assigned_to_id]
          tx = @occupation_persons[issue.assigned_to_id] / 100.00
        end
        total += issue.estimated_hours / tx
      end
    end
    
    total += total_time_switching_issues(list_issues)
    
    format_hours(total, format)
    
  end
  
  # total charge that is not affected to anybody
  def charge_unassigned(format='h')
    
    total = 0
    leaf_issues.each do |issue|
      if issue.assigned_to_id.nil? && !issue.estimated_hours.nil?
        total += issue.estimated_hours
      end
    end
    format_hours(total, format)
    
  end
  
  # total charge left at the end of period
  def charge_left(format='h')
        
    total = charge_initial
    total = charge_effective if total.nil? || total == 0
    
    leaf_issues.each do |issue|
      if issue.estimated_hours
        
        if issue.status.is_closed?
          done_ratio = 100      
        else
          done_ratio = issue.done_ratio ? issue.done_ratio : 0
        end
        
        total -= issue.estimated_hours * ( done_ratio / 100.00 )
        
      end
    end
    
    format_hours(total, format)
    
  end
  
  # return the list of issues which don't have child issues
  def leaf_issues
    issues.select { |issue| leaf? issue }   
  end
  
  private # ----------------------------------------------------------------
  
  def format_occupation_persons_map(occupation_persons)
    if occupation_persons
      return Hash[occupation_persons.keys.map(&:to_i).zip(occupation_persons.values.map(&:to_i))]
    else
      return Hash.new
    end
  end
  
  def format_hours(hours, format)  
    hours = 0 if hours.nil?
    if format == 'd'
       hours = hours / @@nb_hours_per_day
       hours = hours >= 0 ? hours.ceil : hours.floor
    end
    hours   
  end
  
  def leaf?(issue)
    
    childs = Issue.where(parent_id: issue.id)  
    childs.blank?

  end
  
  def date_estimated_for(person)
    
    days_left = time_left_for(person, 'd')
    
    current = @period.date_to
    
    while days_left > 0 do
      current = current + 1.days
      if !current.saturday? && !current.sunday?
        days_left -= 1
      end
    end
    
    current
    
  end
  
  def time_left_for(person, format='h')
    
    total = 0.00
    
    person_id = person ? person.id : nil
    
    list_issues = leaf_issues
    
    list_issues.each do |issue|
      if issue.estimated_hours && issue.assigned_to_id == person_id && !issue.status.is_closed?
          
        done_ratio = issue.done_ratio ? issue.done_ratio : 0
        
        if @occupation_persons[issue.assigned_to_id]
          tx = @occupation_persons[issue.assigned_to_id] / 100.00
        else
          tx = 1
        end

        total += issue.estimated_hours * ( 100 - done_ratio ) / 100.00 / tx       
        
      end
    end
    
    total += total_time_switching_issues(list_issues)
    
    format_hours(total, format)
    
  end
  
  def total_time_switching_issues(list_issues=nil)
    
    total = 0.00
    
    if @time_switching_issues
         
      tx = @time_switching_issues / 100.00
      
      # remove the last element
      list = list_issues ? list_issues : leaf_issues
      list.slice!(-1)
      
      list.each do |issue|
        if issue.estimated_hours
          total += issue.estimated_hours * tx
        end
      end
      
    end
    
    total
  end
  
end