module RequirementToIssueHelper
  
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

  def createIssue(project, parent)
    
    requirement = self
    
    # check if the parameter 'project' is an entire project or a project version
    if project.instance_of? Version
      version = project
      project = version.project
    end  
    
    # get the tracker
    tracker = createTracker(project, requirement)
    
    # get the priority
    priority = IssuePriority.find_or_create_by_name("Normal")

    # get the user
    if requirement.assignee
      user = requirement.assignee
    elsif parent
      user = parent.assigned_to
    else
      user = User.current
    end

    # create a new issue
    issue = Issue.new(
      :author => User.current,
      :tracker => tracker, 
      :project => project,
      :assigned_to => user,
      :priority => priority     
    )
    
    # set the issue's properties from the requirement
    @fields = issue_fields
    @fields.keys.each do |key|
      if (requirement[@fields[key]])
        issue[key] = requirement[@fields[key]]
      end
    end

    # check if it's a sub-issue
    if parent
      
      issue.project = parent.project
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
      
    else
      
      # set the version id
      if version
        issue.fixed_version_id = version.id
      end
      
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
  
  def assign_custom_fields(requirement, issue)
    
    # activate the autoclose custom field for this project/tracker
    autoclose_field = AutocloseIssuePatch::customField(issue.project, issue.tracker) 
    
    # set the value of the autoclose field    
    issue.custom_field_values = { autoclose_field.id => '1' }
    issue.save_custom_field_values
    issue.save
    
  end
  
  def createTracker(project, requirement)
    
    name = requirement.category
    
    tracker = project.trackers.find_by_name(name)
    
    if !tracker
      tracker = project.trackers.create(:name => name)
    end
    
    tracker     
  end

end