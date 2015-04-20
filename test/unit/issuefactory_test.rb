require File.expand_path('../../test_helper', __FILE__)

class IssueFactoryTest < ActiveSupport::TestCase

	self.use_instantiated_fixtures = true
	self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
	fixtures :projects
	fixtures :issue_statuses
	fixtures :issues
	fixtures :users
	fixtures :enumerations

	test "it should create a sub-issue" do	

    requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => "my tracker"
    )
	
		parent = Issue.find(1)		

		issue = requirement.createIssue(parent.project, parent)

		issues = Issue.where(parent_id: parent.id)

		assert_equal 1, issues.count
		assert_equal requirement.name, issues[0].subject
		assert_equal requirement.description, issues[0].description
		assert_equal requirement.category, issues[0].tracker.name

	end

	test "it should create an issue" do	

		requirement = Requirement.new(
		  :name => "my subject",
		  :description => "my description",
		  :category => "my tracker"
		)
	
		project = Project.find(1)	

		issue = requirement.createIssue(project, nil)
		
		issues = Issue.where(project_id: project.id, subject: requirement.name)
		
		assert_equal 1, issues.count
		assert_equal requirement.name, issues[0].subject
		assert_equal requirement.description, issues[0].description
		assert_equal requirement.category, issues[0].tracker.name

	end

	test "it should create an issue then a sub-issue" do	

		project = Project.find(1)
		
		requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => "my tracker"
    )

		issue1 = requirement.createIssue(project, nil)
		
		issues = Issue.where(project_id: project.id, subject: requirement.name)
		assert_equal 1, issues.count
    
    sub_requirement = Requirement.new(
      :name => "my sub issue",
      :description => "my sub desc",
      :category => "my other tracker"
    )

		issue2 = sub_requirement.createIssue(project, issues[0])

		issues = Issue.where(parent_id: issue1.id)
		assert_equal 1, issues.count

	end
	
	test "it should create an issue from a project version" do
	  
	  requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => "my tracker"
    )
  
    project = Project.find(1)
    
    version = Version.new(
      :name => 'Version 1.0 buguée',
      :project_id => project.id
    )
    version.save

    issue = requirement.createIssue(version, nil)
    
    issues = Issue.where(project_id: project.id, subject: requirement.name)
    
    assert_equal 1, issues.count
    assert_equal version.id, issues[0].fixed_version_id

	end
	
	test "it should set the dates of the issue" do
	  
	  requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => "my tracker",
      :effective_date => "20/04/2015".to_date,
      :start_date => "01/04/2015".to_date
    )
    
    project = Project.find(1)
    
    issue = requirement.createIssue(project, nil)
    
    issues = Issue.where(project_id: project.id, subject: requirement.name)
    
    assert_equal 1, issues.count
    assert_equal requirement.start_date, issues[0].start_date
    assert_equal requirement.effective_date, issues[0].due_date
	  
	end
	
	 test "it should use the parent's dates if the children doesn't have dates" do
    
    project = Project.find(1)
    
    requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => "my tracker",
      :effective_date => "20/04/2015".to_date,
      :start_date => "01/04/2015".to_date
    )
    
    root_issue = requirement.createIssue(project, nil)
    
    sub_requirement = Requirement.new(
      :name => "my sub-requirement",
      :description => "my sub-description",
      :category => "my tracker"
    )
    
    child_issue = sub_requirement.createIssue(project, root_issue)
    
    assert_equal requirement.start_date, root_issue.start_date
    assert_equal requirement.effective_date, root_issue.due_date
    assert_equal requirement.start_date, child_issue.start_date
    assert_equal requirement.effective_date, child_issue.due_date
    
  end
  
  test "it should assign a user to an issue" do
    
    project = Project.find(1)
    
    user_login = "jsnow"
    assert_not_nil User.find_by_login(user_login)
    
    requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => "my tracker",
      :assignee_login => user_login
    )
    
    issue = requirement.createIssue(project, nil)
    
    puts issue.assigned_to.inspect
    
    assert_equal user_login, issue.assigned_to.login
    
  end
  
  test "it should assign the parent's user to an issue" do
    
    project = Project.find(1)
    
    user_login = "jsnow"
    
    requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => "my tracker",
      :assignee_login => user_login
    )
    
    issue = requirement.createIssue(project, nil)
    
    sub_requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => "my tracker"
    )
 
    child_issue = sub_requirement.createIssue(project, issue)
    
    assert_equal user_login, child_issue.parent.assigned_to.login
    
  end
  
  test "it should attach a priority to an issue" do
    
    project = Project.find(1)
    
    priority = IssuePriority.find(3)
    
    requirement = Requirement.new(
      :name => "my subject",
      :category => 'my tracker',
      :priority_id => priority.position
    )
    
    issue = requirement.createIssue(project, nil)
    
    assert_equal priority, issue.priority
    
  end
  
  test "it should create a category and attach it to an issue" do
    
    project = Project.find(1)
        
    requirement = Requirement.new(
      :name => "my subject",
      :category => 'my tracker',
      :issue_category_name => 'my super category'
    )
    
    issue = requirement.createIssue(project, nil)
    
    assert_equal requirement.issue_category_name, issue.category.name
    
  end
  
  test "it should attach an existing category to an issue" do
    
    project = Project.find(1)
    issue_category = IssueCategory.find(1)
    
    requirement = Requirement.new(
      :name => "my subject",
      :category => 'my tracker',
      :issue_category_name => issue_category.name
    )
    
    issue = requirement.createIssue(project, nil)

    assert_not_nil issue.category
    assert_equal issue_category, issue.category
    
  end

end
