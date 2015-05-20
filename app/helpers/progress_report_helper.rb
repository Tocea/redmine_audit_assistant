module ProgressReportHelper
  
  # return the list of issues that has been updated during a given period
  def issues_updated(issues, date_from, date_to)
    
    if issues.blank? || date_from.nil? || date_to.nil?
      return Array.new
    end
       
    journals = Journal.where("journalized_type = 'Issue' AND journalized_id IN (:issues_ids) AND created_on >= :date_from AND created_on <= :date_to", {
        issues_ids: issues.map { |issue| issue.id },
        date_from: date_from,
        date_to: date_to
    })
    
    issues_ids_changed = journals.map { |j| j.journalized_id }
    
    issues.select { |issue| issues_ids_changed.include?(issue.id) }
    
  end
  
  # get the last know value of an issue's property before a given date 
  def get_property_value_at_period_end(issue, prop_key, date_to)
    
    if date_to.to_date > Date.today
      return nil
    end
    
    # retrieve all changes on the current property
    # order the list of changes by the journal's creation date
    journal_details = JournalDetail.joins(:journal).where("journals.journalized_type = 'Issue' AND journals.journalized_id = :issue_id AND property = 'attr' AND prop_key = :prop_key", {
        issue_id: issue.id,
        prop_key: prop_key
    }).order("journals.created_on ASC")
    
    if journal_details.blank?
      return nil
    end    
    
    # look for the value
    value = nil   
    journal_details.each do |j|  
      if j.journal.created_on.to_date > date_to.to_date
        break
      end
      value = j.value 
    end
    
    value
    
  end
  
  # restore an issue to its last know state in a given period
  def restore_issue_state(issue, date_from, date_to)
           
    # clone the issue
    old_issue = issue.copy
    
    # set the id (lost during the copy)
    old_issue.id = issue.id
    
    # get the list of all attributes
    props = issue.attributes.to_a
    
    props.each do |p|
      value = get_property_value_at_period_end(issue, p[0], date_to)
      if value
        old_issue.send(p[0]+'=', value)
      end 
    end
    
    old_issue
    
  end
  
end
