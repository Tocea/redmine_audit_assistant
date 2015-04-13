require File.expand_path('../../test_helper', __FILE__)

class GoalTest < ActiveSupport::TestCase

	test "it should call the issue factory and return an issue" do

		name = "My awesome goal"
		desc = "I am an awesome goal"
		tracker = "audit - objectif"

		goal = Goal.new(:name => name, :description => desc)

		parent = mock()
		project = mock()
		issue = mock()
		parent.expects(:project).returns(project)

		AuditHelper::AuditIssueFactory
			.expects(:createIssue)
			.with(name, desc, tracker, project, parent)
			.returns(issue)	

		assert_equal issue, goal.toIssue(parent)

	end

	test "it should call toIssue() method on each practice" do
		
		goal = Goal.new(:name => "My Goal")

		pr1 = stub("practice 1")
		pr2 = stub("practice 2")
		practices = [pr1, pr2]
		goal.stubs(:practices).returns(practices)

		parent = mock()
		project = mock()
		issue = mock()
		parent.expects(:project).returns(project)

		AuditHelper::AuditIssueFactory.expects(:createIssue).returns(issue)
		pr1.expects(:toIssue).with(issue)
		pr2.expects(:toIssue).with(issue)
		goal.toIssue(parent)	

	end
end
