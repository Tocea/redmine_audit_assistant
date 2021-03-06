require File.expand_path('../../test_helper', __FILE__)

class RequirementTest < ActiveSupport::TestCase
  
  self.use_instantiated_fixtures = true
  self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
  fixtures :requirements
  
  test "it should call the issue factory and return an issue" do

    requirement = requirements(:req_001)
    requirement.expects(:children).returns([])
    
    project = mock()
    project.expects(:class).returns(Project)
    issue = mock()
    
    requirement.expects(:createIssue).with({ 
         :project => project, 
         :version => nil, 
         :parent_issue => nil
    }).returns(issue)

    assert_equal issue, requirement.toIssue(project)

  end
 
  test "it should call the toIssue() method on any sub-requirements" do

    requirement = requirements(:req_001)
    
    project = mock()
    project.expects(:class).returns(Project)

    issue = mock()
    issue.expects(:class).at_least_once.returns(Issue)
    issue.expects(:project).at_least_once.returns(project)
    
    requirement.expects(:createIssue).with({ 
      :project => project, 
      :version => nil, 
      :parent_issue => nil 
    }).returns(issue)
    
    requirement.children.each do |child|
      child.expects(:createIssue).with({
        :project => project, 
        :version => nil, 
        :parent_issue => issue 
      })
      child.expects(:children).returns([])
    end

    assert_equal issue, requirement.toIssue(project)

  end 
  
  test "it should look for a User with its login" do
    
    login = 'jsnow'
    
    requirement = requirements(:req_001)
    requirement.assignee_login = login
    
    User.expects(:find_by_login).with(login)
    
    requirement.assignee
    
  end
  
  test "it should attach a priority object to a requirement from a position" do
    
    pos = 1
    
    requirement = requirements(:req_001)
    
    requirement.priority_id = pos
    
    IssuePriority.expects(:find_by_position).with(pos)
    
    requirement.priority
    
  end
  
  test "it should store a checklist in a requirement object" do
    
    requirement = requirements(:req_001)
    
    requirement.checklist = ['string1', 'string2', 'string3']
    
    requirement.save
    
    assert_equal 3, Requirement.find(requirement.id).checklist.length
    
  end

end
