require File.expand_path('../../test_helper', __FILE__)
require 'mocha'

class CategoryTest < ActiveSupport::TestCase

	self.use_instantiated_fixtures = true
	self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
	fixtures :projects
	fixtures :issue_statuses
	fixtures :issues

	#def test_to_issue	
	
	#	parent = Issue.find(1)	
		
	#	category = Category.new(
	#		:name => "my category"
	#	)
	#	category.toIssue(parent)

	#	issues = Issue.where(parent_id: parent.id)
	#	puts issues
	#	assert_equal 1, issues.count
	#	assert_equal category.name, issues[0].subject

	#end

	test "it should call the issue factory and return an issue" do

		name = "My awesome category"
		desc = "I am an awesome category"
		tracker = "audit - catégorie"

		category = Category.new(:name => name, :description => desc)

		parent = mock()
		project = mock()
		issue = mock()
		parent.expects(:project).returns(project)

		AuditHelper::AuditIssueFactory
			.expects(:createIssue)
			.with(name, desc, tracker, project, parent)
			.returns(issue)	

		assert_equal issue, category.toIssue(parent)

	end

	test "it should call toIssue() method on each domain" do
		
		category = Category.new(:name => "My category")

		dom1 = stub("domain 1")
		dom2 = stub("domain 2")
		domains = [dom1, dom2]
		category.stubs(:domains).returns(domains)

		parent = mock()
		project = mock()
		issue = mock()
		parent.expects(:project).returns(project)

		AuditHelper::AuditIssueFactory.expects(:createIssue).returns(issue)
		dom1.expects(:toIssue).with(issue)
		dom2.expects(:toIssue).with(issue)
		category.toIssue(parent)	

	end
end
