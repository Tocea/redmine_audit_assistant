module AutocloseIssuePatch extend ActiveSupport::Concern
  
  class AutocloseIssueHook < Redmine::Hook::ViewListener
    
    def controller_issues_edit_after_save(context={})
      
      Rails.logger.info "running AutoCloseIssueHook..."
      AutocloseIssueHook.run(context[:issue])
     
    end
    
    def controller_issues_bulk_edit_before_save(context={})
      
      Rails.logger.info "running AutoCloseIssueHook from contextual menu..."
      issue = context[:issue]
      issue.save
      AutocloseIssueHook.run(issue)
      
    end
    
    # run the hook
    def self.run(issue)
      
      close_parent_issue(issue)
      
      if issue.fixed_version_id
        version = Version.find(issue.fixed_version_id)
        close_version(version)
      end           

    end
    
    # check if we can automatically close an issue
    #   - the issue must be closed 
    #   - it should have a parent 
    #   - the autoclose option should have been set
    #   - the other issues with the same parent must be closed
    def self.required?(issue)
      
      field = AutocloseIssuePatch::customField(nil, nil)
             
      return false unless (issue.status.is_closed && issue.parent && (issue.custom_value_for(field.id).to_s == '1'))
      
      # check if the other children of its parent are also closed 
      children = Issue.where(parent_id: issue.parent.id)    
      return children.select {|c| c.status.is_closed == false }.empty?
      
    end
    
    def self.close_parent_issue(issue)
      
      # reload the issue
      issue.reload     
                   
      # check if the issue is closed, if it has a parent and if the autoclose option has been set
      if AutocloseIssueHook.required? issue
         
        # close the issue
        issue.parent.status_id = issue.status_id
        issue.parent.save
        
        # do the same with the parent to see if it has a parent that need to be closed
        close_parent_issue(issue.parent)
        
      end
      
    end
    
    # close a version if all its child issues are closed
    def self.close_version(version)
      
      required = false
      
      if version
        children = Issue.where(fixed_version_id: version.id)
        if children.count == 0
          # if the version has no issue, then no need to close it yet!
          required = false
        else
          # check if the issues are all closed
          required = children.select {|c| c.status.is_closed == false }.empty?
        end
      end
      
      if required       
        version.status = 'closed'
        version.save    
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