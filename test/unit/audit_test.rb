require File.expand_path('../../test_helper', __FILE__)
require 'mocha'

class AuditTest < ActiveSupport::TestCase

	#self.use_instantiated_fixtures = true
	#self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
	#fixtures :projects
	#fixtures :issue_statuses

	#def test_to_issue	

	#	puts Project.find(:all)		
	#	project = Project.find(1)	
	#	assert_equal "test_project", project.name
	#	
	#	audit = Audit.new
	#	audit.name = "My Audit"
	#	audit.toIssue(project)

	#	issues = Issue.where(project_id: project.id)
	#	puts issues
	#	assert_equal 1, issues.count
	#	assert_equal audit.name, issues[0].subject

	#end

	test "it should call the issue factory and return an issue" do

		name = "My awesome audit"
		tracker = "audit"

		audit = Audit.new(:name => name)

		project = mock()
		issue = mock()

		AuditHelper::AuditIssueFactory
			.expects(:createIssue)
			.with(name, "", tracker, project, nil)
			.returns(issue)	

		assert_equal issue, audit.toIssue(project)

	end

	test "it should call toIssue() method on each category" do
		
		audit = Audit.new
		audit.name = "My Audit"

		cat1 = stub("category 1")
		cat2 = stub("category 2")
		categories = [cat1, cat2]
		audit.stubs(:categories).returns(categories)

		project = mock()
		issue = mock()

		AuditHelper::AuditIssueFactory.expects(:createIssue).returns(issue)
		cat1.expects(:toIssue).with(issue)
		cat2.expects(:toIssue).with(issue)
		audit.toIssue(project)	

	end

end
