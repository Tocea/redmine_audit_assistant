require File.expand_path('../../test_helper', __FILE__)

class AutocloseIssueTest < ActiveSupport::TestCase

  self.use_instantiated_fixtures = true
  self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
  fixtures :projects
  fixtures :issue_categories
  fixtures :issue_statuses
  fixtures :issues
  fixtures :trackers
  fixtures :users
  
  def priority
    priority = IssuePriority.new(:id => 1, :name => 'normal')
    priority.save
    priority
  end
  
  def mock_custom_field
    field = mock()
    field.expects(:id).at_least_once().returns(1)
    AutocloseIssuePatch.expects(:customField).at_least_once().with(nil, nil).returns(field)
    Issue.any_instance.stubs(:custom_value_for).with(1).returns('1')
  end
  
  test "it should close the parent issue when all child issues are closed" do
    
    mock_custom_field
    
    # close an issue
    issue = Issue.find(3)
    issue.status_id = 5
    issue.priority = priority 
    issue.save
    assert issue.status.is_closed
    
    # the parent issue must not be closed
    assert !issue.parent.status.is_closed
    
    # the current issue is the only child issue
    assert_equal 1, Issue.where(parent_id: issue.parent.id).count
    
    AutocloseIssuePatch::AutocloseIssueHook.close_parent_issue(issue)
    
    assert issue.parent.status.is_closed
    
  end
  
  test "it should not close the parent issue if the autoclose option has not been set" do
    
    # close an issue
    issue = Issue.find(3)
    issue.status_id = 5
    issue.priority = priority 
    issue.save  
    assert issue.status.is_closed
    
    # the parent issue must not be closed
    assert !issue.parent.status.is_closed
    
    # the current issue is the only child issue
    assert_equal 1, Issue.where(parent_id: issue.parent.id).count
    
    AutocloseIssuePatch::AutocloseIssueHook.close_parent_issue(issue)
    
    assert !issue.parent.status.is_closed
    
  end
  
  test "it should recursively close all the parent issues if all the child issues are closed" do
    
    mock_custom_field
    
    # close an issue
    issue = Issue.find(4)
    issue.status_id = 5
    issue.priority = priority
    issue.save  
    assert issue.status.is_closed 
    
    # the parent issue and its parent must not be closed    
    assert !issue.parent.status.is_closed
    assert !issue.parent.parent.status.is_closed
    
    # the current issue is the only child issue
    assert_equal 1, Issue.where(parent_id: issue.parent.id).count
    
    AutocloseIssuePatch::AutocloseIssueHook.close_parent_issue(issue)
    
    # the parent issue and its parent must now be closed
    assert issue.parent.status.is_closed
    assert issue.parent.parent.status.is_closed
    
  end
  
  test "it should not close the parent issue if a child issue is still open" do
    
    mock_custom_field
    
    # close an issue
    issue = Issue.find(5)
    issue.status_id = 5
    issue.priority = priority
    issue.save  
    assert issue.status.is_closed 
    
    # the parent issue must not be closed
    assert !issue.parent.status.is_closed
    
    # the parent issue has 2 child issues and one is still opened
    children = Issue.where(parent_id: issue.parent.id)
    assert_equal 2, children.count
    assert !children.select {|c| c.status.is_closed == false }.empty?
    
    AutocloseIssuePatch::AutocloseIssueHook.close_parent_issue(issue)
    
    # the parent issue must still be opened
    assert !issue.parent.status.is_closed
    
  end
  
  test "it should create a custom field" do
    
    # verify that we don't already have a custom field
    assert_equal 0, IssueCustomField.count
    
    # create the custom field
    field = AutocloseIssuePatch::customField(nil, nil)
    
    # a custom field should have been returned
    assert_not_nil field
    
    # a custom field should have been created
    assert_equal 1, IssueCustomField.count
    
  end
  
  test "it should not create another custom field if it is already defined" do
    
    # create the custom field
    AutocloseIssuePatch::customField(nil, nil)
    
    # a custom field should have been created
    assert_equal 1, IssueCustomField.count
    
    # get the custom field
    field = AutocloseIssuePatch::customField(nil, nil)
    
    # another custom field should not have been created
    assert_equal 1, IssueCustomField.count
    
  end
  
  test "it should enable the custom field for a project" do
    
    project = Project.find(1)
    
    # create the custom field
    field = AutocloseIssuePatch::customField(project, nil)
    
    # the project should be included in the custom field projects list
    assert field.projects.include? project

  end
  
  test "it should enable the custom field for a tracker" do
    
    tracker = Tracker.find(1)
    
    # create the custom field
    field = AutocloseIssuePatch::customField(nil, tracker)
    
    # the tracker should be included in the custom field trackers list
    assert field.trackers.include? tracker
    
  end
  
end