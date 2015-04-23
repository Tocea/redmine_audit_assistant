require File.expand_path('../../test_helper', __FILE__)

class RequirementTest < ActiveSupport::TestCase

	self.use_instantiated_fixtures = :no_instances
	self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
	fixtures :projects
	fixtures :issue_statuses
	fixtures :requirements
	fixtures :enumerations

	test "we should be able to create issues from a requirement instance" do
	
	  nb_issues = Issue.count
	
	  # get the objects from the fixtures
		project = projects(:test_project) #Project.find(1)			
		requirement = requirements(:req_001) #Requirement.find(1)
		
		# convert the audit to issues
		requirement.toIssue(project)

    # verify that an issue has been created for the root requirement
		issues = Issue.where(subject: requirement.name)
		assert_equal 1, issues.count
		
		# verify that an issue has been created for each sub requirement
		lookup(requirement, issues[0])
		
		# verify that the number of issues created is exactly
		# the same as the number of requirements defined
		assert_equal nb_issues+5, Issue.count
		
	end
	
	def lookup(req, issue)   
    req.children.each do |child|           
      issues = Issue.where(parent_id: issue.id, subject: child.name)
      assert_equal 1, issues.count
      lookup(child, issues[0])      
    end
  end

end
