class IssueStatusActions < ActiveRecord::Base
  
  belongs_to :status_from, :class_name => 'IssueStatus', foreign_key: "status_id_from"
  belongs_to :status_to, :class_name => 'IssueStatus', foreign_key: "status_id_to"
  
  # check if the action's data are correct
  def valid?(context=nil)
    !lib.blank? && !status_from.nil? && !status_to.nil? && status_id_from != status_id_to 
  end
  
  # get the list of actions that are available for a specific issue
  def self.available_actions(issue)
        
    actions = IssueStatusActions.where(status_id_from: issue.status.id)
    
    status_allowed = issue.new_statuses_allowed_to.map { |st| st.id }
    
    actions.select { |action| status_allowed.include? action.status_id_to }
    
  end
  
  # run the current action on an issue to change its status
  def run(issue)
    
    user = User.current
    return nil unless user && user.allowed_to?(:log_time, issue.project)
    
    status_allowed = issue.new_statuses_allowed_to
    
    if status_id_from == issue.status.id && status_allowed.include?(status_to)
         
      journal = issue.init_journal(user)
      issue.status = status_to
      issue.save
       
      AutocloseIssuePatch::AutocloseIssueHook.run(issue)
      #Redmine::Hook.call_hook(:controller_issues_edit_after_save, { :issue => issue })
      
      issue
    
    end
    
  end
  
  # assign the issue to the current user
  def self.take_task(issue)
    
    user = User.current
    return nil unless user && user.allowed_to?(:log_time, issue.project)
    
    issue.init_journal(user)
    issue.assigned_to = user
    issue.save
    
    issue
  end
  
end