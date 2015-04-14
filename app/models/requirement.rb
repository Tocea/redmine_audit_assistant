class Requirement < ActiveRecord::Base
  
  belongs_to :requirement
  has_many :children, :class_name => 'Requirement', foreign_key: "requirement_id"
  
  attr_accessor :issue
  
  @issue = nil
  
  def toIssue(parent)
    
    if parent.instance_of? Issue
      parent_issue = parent
      project = parent.project
    else
      project = parent
      parent_issue = nil  
    end
    
    @issue = AuditHelper::AuditIssueFactory
        .createIssue(self, project, parent_issue)

    self.children.each do |child|
      child.toIssue(issue)
    end

    @issue
  end
  
end
