module AutocloseIssuePatch extend ActiveSupport::Concern
  
  class AutocloseIssueHook < Redmine::Hook::ViewListener
    
    def controller_issues_edit_after_save(context={})
      
      Rails.logger.info "running AutoCloseIssueHook..."
      AutocloseIssueHook.close_parent_issue(context[:issue])
     
    end
    
    def controller_issues_bulk_edit_before_save(context={})
      
      Rails.logger.info "running AutoCloseIssueHook from contextual menu..."
      issue = context[:issue]
      issue.save
      AutocloseIssueHook.close_parent_issue(issue)
      
    end
    
    def self.close_parent_issue(issue)
      
      # reload the issue
      issue.reload     
      
      field = AutocloseIssuePatch::customField(nil, nil)     
      
      # check if the issue is closed, if it has a parent and if the autoclose option has been set
      if issue.status.is_closed && issue.parent && (issue.custom_value_for(field.id).to_s == '1')
        
        # check if the other children of its parent are also closed 
        children = Issue.where(parent_id: issue.parent.id)
        if children.select {|c| c.status.is_closed == false }.empty?
          
          # close the issue
          issue.parent.status_id = issue.status_id
          issue.parent.save
          
          # do the same with the parent to see if it has a parent that need to be closed
          close_parent_issue(issue.parent)
        
        end
        
      end
      
    end
    
    
    
  end
  
  def self.customField(project, tracker)
      
    name = 'autoclose parent'
    
    field = IssueCustomField.find_by_name(name)
    
    if !field
      
      field = IssueCustomField.new(
        :name => name,
        :field_format => 'bool',
        :description => 'Automatically close the parent issue of an issue if there is no more child issues opened',
        :edit_tag_style => 'check_box'
      )      
      
    end
    
    if project && (!field.projects.include? project)
      field.projects.push(project)
    end
    
    if tracker && (!field.trackers.include? tracker)
      field.trackers.push(tracker)
    end
    
    field.save
    
    field      
  end
  
end