module ProgressReportHelper
  
  # return the journals of given issues during a particular period  
  def get_issues_journals(issues, date_from, date_to)
    
    if issues.blank? || date_from.nil? || date_to.nil?
      return Array.new
    end
       
    journals = Journal.where("journalized_type = 'Issue' AND journalized_id IN (:issues_ids) AND created_on >= :date_from AND created_on <= :date_to", {
        issues_ids: issues.map { |issue| issue.id },
        date_from: date_from,
        date_to: date_to
    })
    
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
    
    # check if the issue existed during the given period
    if issue.created_on.to_date > date_to.to_date
      return nil
    end
    
    # clone the issue
    old_issue = issue.copy
    
    # set the properties lost during the copy
    old_issue.id = issue.id
    old_issue.created_on = issue.created_on
    
    # get the list of all attributes
    props = issue.attributes.to_a
    
    # reject the attributes that cannot be changed
    props.reject { |p| ['id', 'created_on'].include? p[0] }
    
    props.each do |p|
      value = get_property_value_at_period_end(issue, p[0], date_to)
      if value
        old_issue.send(p[0]+'=', value)
      end 
    end
    
    old_issue
    
  end
  
  def restore_issues_states(issues, date_from, date_to)
    issues_list = issues
    if date_from && date_to
      issues_list = issues.map { |issue| restore_issue_state(issue, date_from, date_to) }.compact
    end
    issues_list
  end
  
end
