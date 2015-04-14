require File.expand_path('../../test_helper', __FILE__)

class IssueFactoryTest < ActiveSupport::TestCase

	self.use_instantiated_fixtures = true
	self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
	fixtures :projects
	fixtures :issue_statuses
	fixtures :issues

	test "it should create a sub-issue" do	

    requirement = Requirement.new(
      :name => "my subject",
      :description => "my description",
      :category => "my tracker"
    )
	
		parent = Issue.find(1)		

		issue = AuditHelper::AuditIssueFactory
				.createIssue(requirement, parent.project, parent)

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

		issue = AuditHelper::AuditIssueFactory
				.createIssue(requirement, project, nil)
		
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

		issue1 = AuditHelper::AuditIssueFactory
				.createIssue(requirement, project, nil)
		
		issues = Issue.where(project_id: project.id, subject: requirement.name)
		assert_equal 1, issues.count
    
    sub_requirement = Requirement.new(
      :name => "my sub issue",
      :description => "my sub desc",
      :category => "my other tracker"
    )

		issue2 = AuditHelper::AuditIssueFactory
				.createIssue(sub_requirement, project, issues[0])

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

    issue = AuditHelper::AuditIssueFactory
        .createIssue(requirement, version, nil)
    
    issues = Issue.where(project_id: project.id, subject: requirement.name)
    
    assert_equal 1, issues.count
    assert_equal version.id, issues[0].fixed_version_id

	end

end
