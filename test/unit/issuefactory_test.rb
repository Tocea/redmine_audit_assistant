require File.expand_path('../../test_helper', __FILE__)

class IssueFactoryTest < ActiveSupport::TestCase

	self.use_instantiated_fixtures = true
	self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
	fixtures :projects
	fixtures :issue_statuses
	fixtures :issue_categories
	fixtures :issues
	fixtures :users
	fixtures :enumerations
	fixtures :trackers
	
	setup do
	  @tracker = Tracker.find(1)
	  @project = Project.find(1)
	  @project.trackers << @tracker
	end

	test "it should create a sub-issue" do	

    requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => @tracker.name
    )
	
		parent = Issue.find(1)		

		issue = requirement.toIssue(parent)

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
		  :category => @tracker.name
		)

		issue = requirement.toIssue(@project)
		
		issues = Issue.where(project_id: @project.id, subject: requirement.name)
		
		assert_equal 1, issues.count
		assert_equal requirement.name, issues[0].subject
		assert_equal requirement.description, issues[0].description
		assert_equal requirement.category, issues[0].tracker.name

	end

	test "it should create an issue then a sub-issue" do	
		
		requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => @tracker.name
    )

		issue1 = requirement.toIssue(@project)
		
		issues = Issue.where(project_id: @project.id, subject: requirement.name)
		assert_equal 1, issues.count
    
    sub_requirement = Requirement.new(
      :name => "my sub issue",
      :description => "my sub desc",
      :category => @tracker.name
    )

		issue2 = sub_requirement.toIssue(issues[0])

		issues = Issue.where(parent_id: issue1.id)
		assert_equal 1, issues.count

	end
	
	test "it should create an issue from a project version" do
	  
	  requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => @tracker.name
    )
    
    version = Version.new(
      :name => 'Version 1.0 buguée',
      :project_id => @project.id
    )
    version.save

    issue = requirement.toIssue(version)
    
    issues = Issue.where(project_id: @project.id, subject: requirement.name)
    
    assert_equal 1, issues.count
    assert_equal version.id, issues[0].fixed_version_id

	end
	
	test "it should set the dates of the issue" do
	  
	  requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => @tracker.name,
      :effective_date => "20/04/2015".to_date,
      :start_date => "01/04/2015".to_date
    )
    
    issue = requirement.toIssue(@project)
    
    issues = Issue.where(project_id: @project.id, subject: requirement.name)
    
    assert_equal 1, issues.count
    assert_equal requirement.start_date, issues[0].start_date
    assert_equal requirement.effective_date, issues[0].due_date
	  
	end
	
	 test "it should use the parent's dates if the children doesn't have dates" do
    
    requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => @tracker.name,
      :effective_date => "20/04/2015".to_date,
      :start_date => "01/04/2015".to_date
    )
    
    root_issue = requirement.toIssue(@project)
    
    sub_requirement = Requirement.new(
      :name => "my sub-requirement",
      :description => "my sub-description",
      :category => @tracker.name
    )
    
    child_issue = sub_requirement.toIssue(root_issue)
    
    assert_equal requirement.start_date, root_issue.start_date
    assert_equal requirement.effective_date, root_issue.due_date
    assert_equal requirement.start_date, child_issue.start_date
    assert_equal requirement.effective_date, child_issue.due_date
    
  end
  
  test "it should assign a user to an issue" do

    user_login = "jsnow"
    assert_not_nil User.find_by_login(user_login)
    
    requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => @tracker.name,
      :assignee_login => user_login
    )
    
    issue = requirement.toIssue(@project)
    
    puts issue.assigned_to.inspect
    
    assert_equal user_login, issue.assigned_to.login
    
  end
  
  test "it should assign the parent's user to an issue" do
    
    user_login = "jsnow"
    
    requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => @tracker.name,
      :assignee_login => user_login
    )
    
    issue = requirement.toIssue(@project)
    
    sub_requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => @tracker.name
    )
 
    child_issue = sub_requirement.toIssue(issue)
    
    assert_equal user_login, child_issue.parent.assigned_to.login
    
  end
  
  test "it should not fail if a non-existing user is assigned to an issue" do
    
    user_login = "nobody"
    
    requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => @tracker.name,
      :assignee_login => user_login
    )
    
    issue = requirement.toIssue(@project)
    
    puts issue.assigned_to.inspect
    
    assert_equal User.current.login, issue.assigned_to.login
    
  end
  
  test "it should attach a priority to an issue" do
    
    priority = IssuePriority.find(3)
    
    requirement = Requirement.new(
      :name => "my subject",
      :category => @tracker.name,
      :priority_id => priority.position
    )
    
    issue = requirement.toIssue(@project)
    
    assert_equal priority, issue.priority
    
  end
  
  test "it should create a category and attach it to an issue" do

    requirement = Requirement.new(
      :name => "my subject",
      :category => @tracker.name,
      :issue_category_name => 'my super category'
    )
    
    issue = requirement.toIssue(@project)
    
    assert_equal requirement.issue_category_name, issue.category.name
    
  end
  
  test "it should attach an existing category to an issue" do
    
    issue_category = IssueCategory.find(1)
    
    requirement = Requirement.new(
      :name => "my subject",
      :category => @tracker.name,
      :issue_category_name => issue_category.name
    )
    
    issue = requirement.toIssue(@project)

    assert_not_nil issue.category
    assert_equal issue_category, issue.category
    
  end
  
  test "it should include the checklist module" do
    
    modules = Requirement.ancestors.select{|o| o.class == Module }
    
    assert modules.include? ChecklistHelper
    
  end
  
  test "it should assign the version's effective date to an issue if no due date specified" do
    
    requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => @tracker.name
    )
  
    version = Version.new(
      :name => 'Version 1.0 buguée',
      :project_id => @project.id,
      :effective_date => Date.new(2015,5,19)
    )
    version.save

    issue = requirement.toIssue(version)
    
    issues = Issue.where(project_id: @project.id, subject: requirement.name)
    
    assert_equal 1, issues.count
    assert_equal version.effective_date, issues[0].due_date
    
  end
  
  test "it should fail to create an issue if the given tracker does not exist" do
    
    requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => "Something"
    )

    assert_raise ArgumentError do
      issue = requirement.toIssue(@project)
    end
    
    issues = Issue.where(project_id: @project.id, subject: requirement.name)
    
    assert_equal 0, issues.count
    
  end

end
