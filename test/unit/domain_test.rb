require File.expand_path('../../test_helper', __FILE__)

class DomainTest < ActiveSupport::TestCase

	test "it should call the issue factory and return an issue" do

		name = "My awesome domain"
		desc = "I am an awesome domain"
		tracker = "audit - domaine"

		domain = Domain.new(:name => name, :description => desc)

		parent = mock()
		project = mock()
		issue = mock()
		parent.expects(:project).returns(project)

		AuditHelper::AuditIssueFactory
			.expects(:createIssue)
			.with(name, desc, tracker, project, parent)
			.returns(issue)	

		assert_equal issue, domain.toIssue(parent)

	end

	test "it should call toIssue() method on each goal" do
		
		domain = Domain.new(:name => "My domain")

		goal1 = stub("goal 1")
		goal2 = stub("goal 2")
		goals = [goal1, goal2]
		domain.stubs(:goals).returns(goals)

		parent = mock()
		project = mock()
		issue = mock()
		parent.expects(:project).returns(project)

		AuditHelper::AuditIssueFactory.expects(:createIssue).returns(issue)
		goal1.expects(:toIssue).with(issue)
		goal2.expects(:toIssue).with(issue)
		domain.toIssue(parent)	

	end
end
