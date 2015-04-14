require File.expand_path('../../test_helper', __FILE__)

class RequirementTest < ActiveSupport::TestCase
  
  self.use_instantiated_fixtures = true
  self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
  fixtures :requirements
  
  test "it should load fixtures" do
    requirements = Requirement.find(:all)
    assert requirements.count > 0
  end
  
  test "it should call the issue factory and return an issue" do

    requirement = requirements(:req_001)
    requirement.expects(:children).returns([])
    
    project = mock()
    project.expects(:instance_of?).with(Issue).returns(false)
    issue = mock()
    
    AuditHelper::AuditIssueFactory
      .expects(:createIssue)
      .with(requirement, project, nil)
      .returns(issue)

    assert_equal issue, requirement.toIssue(project)

  end
 
  test "it should call the toIssue() method on any sub-requirements" do

    requirement = requirements(:req_001)
    
    project = mock()
    project.expects(:instance_of?).with(Issue).returns(false)
    issue = mock()
    issue.expects(:project).at_least_once().returns(project)
    issue.expects(:instance_of?).at_least_once().with(Issue).returns(true)
    
    AuditHelper::AuditIssueFactory
      .expects(:createIssue)
      .with(requirement, project, nil)
      .returns(issue)
    
    requirement.children.each do |child|
      AuditHelper::AuditIssueFactory
        .expects(:createIssue)
        .with(child, project, issue)
      child.expects(:children).returns([])
    end

    assert_equal issue, requirement.toIssue(project)

  end 

end
