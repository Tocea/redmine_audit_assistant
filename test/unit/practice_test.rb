require File.expand_path('../../test_helper', __FILE__)

class PracticeTest < ActiveSupport::TestCase

	test "it should call the issue factory and return an issue" do

		name = "My awesome domain"
		desc = "I am an awesome domain"
		tracker = "audit - pratique"

		practice = Practice.new(:name => name, :description => desc)

		parent = mock()
		project = mock()
		issue = mock()
		parent.expects(:project).returns(project)

		AuditHelper::AuditIssueFactory
			.expects(:createIssue)
			.with(name, desc, tracker, project, parent)
			.returns(issue)	

		assert_equal issue, practice.toIssue(parent)

	end

end
