class DateEstimationStrategy
  
  def initialize(progress_report, time_formatter=nil)
    
    @report = progress_report
    @time_formatter = time_formatter ? time_formatter : TimeFormatter.new
    
  end
  
  def calculate()
    
    # get the estimated date of the end of every person's work
    dates = @report.users.map { |user| date_estimated_for(user) }
    
    # add the estimated date of the work not assigned to anybody
    dates.push(date_estimated_for(nil))
    
    # take the maximum date
    dates.max
    
  end
  
  private # ------------------------------------------------------
  
  def date_estimated_for(person)
    
    days_left = time_left_for(person, 'd')
    
    current = @report.period.date_to
    
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
    
    person_id = nil
    
    if person
      
      person_id = person.id
      
      # add the number of hours that this person cannot work
      total += @report.data.person_total_time_off(person.id)
      
    end
    
    list_issues = @report.leaf_issues
    
    list_issues.each do |issue|
      if issue.estimated_hours && issue.assigned_to_id == person_id
          
        occupation_rate = @report.data.person_occupation_rate(issue.assigned_to_id) 
          
        total += issue.estimated_hours * @report.issue_todo_ratio(issue) / occupation_rate
        
      end
    end
    
    # add the time necessary to switch between issues
    total += @report.data.total_time_switching_issues(list_issues)
    
    @time_formatter.format_hours(total, format)
    
  end
  
end