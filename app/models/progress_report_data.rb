class ProgressReportData
  
  attr_reader :occupation_persons, :time_switching_issues, :days_off
  
  def initialize(params={})
    
    @occupation_persons = params[:occupation_persons] ? params[:occupation_persons] : {}
    @time_switching_issues = params[:time_switching_issues].to_f / 100
    @days_off = params[:days_off] ? params[:days_off] : {} 
    @time_formatter = params[:time_formatter]
  end
  
  def person_occupation_rate(person_id)
    
    if @occupation_persons[person_id]
      tx = @occupation_persons[person_id] / 100.00
    else
      tx = 1
    end
    
    tx
  end
  
  def person_total_time_off(person_id, format='h')
    
    nb = @days_off[person_id] ? @days_off[person_id] : 0
    
    @time_formatter.format_days(nb, format)

  end
  
  def total_time_switching_issues(list_issues)
    
    total = 0.00
    
    if @time_switching_issues && !list_issues.blank?
         
      # remove the last element
      list = list_issues
      list.slice!(-1)
      
      list.each do |issue|
        if issue.estimated_hours
          total += issue.estimated_hours * @time_switching_issues
        end
      end
      
    end
    
    total
  end
  
end