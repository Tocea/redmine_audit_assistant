module RequirementToIssueHelper
  
  # include ChecklistHelper into the class into which this module is included
  def self.included klass
    klass.class_eval do
      include ChecklistHelper
    end
  end
  
  # mapping of the properties of an issue with the properties of a requirement
  def issue_fields 
    {
      :subject => 'name',
      :description => 'description',
      :estimated_hours => 'charge',
      :start_date => 'start_date',
      :due_date => 'effective_date'
    }
  end
  
  # convert a requirement and all its children to Redmine issues
  def toIssue(parent)
    
    # check parent type
    case parent.class.to_s
    when 'Issue'
      parent_issue = parent
      project = parent.project
      version = nil
    when 'Project'
      project = parent
      parent_issue = nil
      version = nil
    when 'Version'
      version = parent
      project = version.project
      parent_issue = nil
    else
      puts parent.class.to_s+' not found'
      return nil
    end  
    
    self.issue = createIssue(
      :project => project, 
      :version => version,
      :parent_issue => parent_issue
     )

    self.children.each do |child|
      child.toIssue(issue)
    end

    self.issue
  end

  # create an issue from a requirement
  def createIssue(args)
    
    project = args[:project]
    version = args[:version]
    parent = args[:parent_issue]
    
    requirement = self
    
    # get the tracker
    tracker = get_or_create_tracker(project, requirement)
    
    # get the issue category
    issue_category = get_or_create_issue_category(project, requirement)
    
    # get the priority from the requirement, the parent issue
    # or use the default priority
    priority = requirement.priority
    priority = parent.priority if !priority && parent
    priority = IssuePriority.default if !priority

    # get the user
    user = requirement.assignee
    user = parent.assigned_to if !user && parent
    user = User.current if !user

    # create a new issue
    issue = Issue.new(
      :author => User.current,
      :tracker => tracker, 
      :project => project,
      :assigned_to => user,
      :priority => priority
    )
    
    # set the category
    if issue_category
      issue.category = issue_category
    end
    
    # set the issue's properties from the requirement
    @fields = issue_fields
    @fields.keys.each do |key|
      if (requirement[@fields[key]])
        issue[key] = requirement[@fields[key]]
      end
    end

    # check if it's a sub-issue
    if parent
      
      assign_from_parent(issue, parent)
     
    end 
    
    if version
      
      # set the version id if it hasn't been inherited from parent
      issue.fixed_version_id = version.id unless issue.fixed_version_id
      
      # set due date to the version's effective date
      # if no due date have been assigned yet
      issue.due_date = version.effective_date unless issue.due_date
      
    end    

    # check if the issue can be validated
    if !issue.valid?
      puts issue.errors.full_messages
    end

    # save the issue
    issue.save
    
    # assign custom fields
    assign_custom_fields(requirement, issue)
    
    issue
    
  end
  
  # assign properties to an issue from its parent
  def assign_from_parent(issue, parent)
    
    issue.parent = parent
    issue.fixed_version_id = parent.fixed_version_id    
    
    # if no start_date specified, use the parent's one
    if parent.start_date && !issue.start_date
      issue.start_date = parent.start_date
    end
    
    # if no due_date specified, use the parent's one
    if parent.due_date && !issue.due_date
      issue.due_date = parent.due_date
    end
    
    # get the root of the issue(s)
    root = issue
    while root.parent
      root = root.parent
    end
    issue.root_id = root.id
    
    issue
  end
  
  # set custom fields values
  def assign_custom_fields(requirement, issue)
    
    # activate the autoclose custom field for this project/tracker
    autoclose_field = AutocloseIssuePatch::customField(issue.project, issue.tracker) 
    
    # set the value of the autoclose field    
    issue.custom_field_values = { autoclose_field.id => '1' }
    issue.save_custom_field_values
    issue.save
    
    # create issue checklist
    create_issue_checklist(requirement, issue)
    
  end
  
  # retrieve a tracker from a requirement instance
  # or create one if it doesn't exist yet
  def get_or_create_tracker(project, requirement)
    
    name = requirement.category
    
    tracker = project.trackers.find_by_name(name)
    
    if !tracker
      tracker = project.trackers.create(:name => name)
    end
    
    tracker     
  end
  
  # retrieve an issue category from a requirement instance
  # or create one if it doesn't exist yet
  def get_or_create_issue_category(project, requirement)
    
    category = nil
    name = requirement.issue_category_name
    
    if name
      
      category = IssueCategory.where(project_id: project.id, name: name).first
      
      if !category
        category = IssueCategory.new(:project_id => project.id, :name => name)
        category.save
      end      
      
    end
    
    category
  end

end