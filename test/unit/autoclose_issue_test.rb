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
  
  def close_issue(issue)
    issue.status_id = 5
    issue.priority = priority    
    if !issue.valid?
      puts issue.errors.full_messages
    end
    issue.save
    assert issue.status.is_closed
  end
  
    
  test "it should react to hook controller_issues_edit_after_save" do
    
    issue = stub()
    issue.expects(:fixed_version_id).returns(nil)
    
    AutocloseIssuePatch::AutocloseIssueHook.stubs(:close_parent_issue).returns(nil)
    AutocloseIssuePatch::AutocloseIssueHook.stubs(:set_date_start).returns(nil)
    
    Redmine::Hook.call_hook(:controller_issues_edit_after_save, { :issue => issue })
    
  end
  
  test "it should react to hook controller_issues_bulk_edit_before_save" do
    
    issue = stub()
    issue.expects(:fixed_version_id).returns(nil)
    issue.expects(:save).returns(true)
    
    AutocloseIssuePatch::AutocloseIssueHook.stubs(:close_parent_issue).returns(nil)
    AutocloseIssuePatch::AutocloseIssueHook.stubs(:set_date_start).returns(nil)
    
    Redmine::Hook.call_hook(:controller_issues_bulk_edit_before_save, { :issue => issue })
    
  end
  
  test "it should close the parent issue when all child issues are closed" do
    
    mock_custom_field
    
    # close an issue
    issue = Issue.find(3)
    close_issue issue
    
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
    close_issue issue
    
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
    close_issue issue
    
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
    close_issue issue
    
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
  
  test "it should close the version if all child issues are closed" do
    
    # get an issue
    issue = Issue.find(1) 
    
    # create a version
    version = Version.new(
      :name => 'version1',
      :description => 'description',
      :project_id => issue.project_id
    )
    version.save
    
    # close the issue
    close_issue issue
    
    # the issue should not have a parent
    assert_nil issue.parent
    
    # assign the version to the issue
    issue.fixed_version_id = version.id
    issue.save
    
    # the version should be attached to only one issue
    assert_equal 1, Issue.where(fixed_version_id: version.id).count
    
    # the version should not be closed yet
    assert_equal 'open', version.status
    
    # run the function
    AutocloseIssuePatch::AutocloseIssueHook.close_version(version)
    
    # the version should now be closed
    assert_equal 'closed', version.status
    
  end
  
  test "it should not close the version if a child issue is still open" do
    
    # get an issue
    issue = Issue.find(1) 
    issue.priority = priority  
    issue.save
    
    # create a version
    version = Version.new(
      :name => 'version1',
      :description => 'description',
      :project_id => issue.project_id
    )
    version.save
    
    # the issue should not be closed
    assert !issue.status.is_closed
    
    # the issue should not have a parent
    assert_nil issue.parent
    
    # assign the version to the issue
    issue.fixed_version_id = version.id
    issue.save
    
    # the version should be attached to only one issue
    assert_equal 1, Issue.where(fixed_version_id: version.id).count
    
    # the version should not be closed yet
    assert_equal 'open', version.status
    
    # run the function
    AutocloseIssuePatch::AutocloseIssueHook.close_version(version)
    
    # the version should not have been closed
    assert_equal 'open', version.status
    
  end
  
  test "it should not close the version if there is no child issue" do
    
    project = Project.find(1)
   
    # create a version
    version = Version.new(
      :name => 'version1',
      :description => 'description',
      :project_id => project.id
    )
    version.save
    
    # the version should not be attached to issues
    assert_equal 0, Issue.where(fixed_version_id: version.id).count
    
    # the version should not be closed yet
    assert_equal 'open', version.status
    
    # run the function
    AutocloseIssuePatch::AutocloseIssueHook.close_version(version)
    
    # the version should not have been closed
    assert_equal 'open', version.status
    
  end
  
  test "it should automatically set the start date of an issue when its status is no longer the default status" do
    
    # get an issue
    issue = Issue.find(1) 
    issue.start_date = nil
    issue.priority = priority
    issue.save
    
    # its status should be the default one
    assert issue.status.is_default
    
    # its start date should not have been set
    assert issue.start_date.nil?
    
    # let's change the status
    issue.status = IssueStatus.find(2)
    issue.save
    
    AutocloseIssuePatch::AutocloseIssueHook.set_date_start(issue)
    
    # the date should now be set
    assert_not_nil issue.start_date
    
  end
  
  test "it should not automatically set the start date of an issue if the start date is already defined" do
    
    start_date = 3.day.ago.to_date
    
    # get an issue
    issue = Issue.find(1) 
    issue.priority = priority
    issue.save
    
    # its status should be the default one
    assert issue.status.is_default
    
    # let's change the status and set a start date
    issue.status = IssueStatus.find(2)
    issue.start_date = start_date
    issue.save
    
    AutocloseIssuePatch::AutocloseIssueHook.set_date_start(issue)
    
    # the date should not have changed
    assert_equal start_date, issue.start_date
    
  end
  
  test "it should not automatically set the start date of an issue which is still on the default status" do
    
    # get an issue
    issue = Issue.find(1) 
    issue.start_date = nil
    issue.priority = priority
    issue.save
    
    # its status should be the default one
    assert issue.status.is_default
    
    # its start date should not have been set
    assert issue.start_date.nil?
    
    AutocloseIssuePatch::AutocloseIssueHook.set_date_start(issue)
    
    # the date should not be set
    assert issue.start_date.nil?
    
  end
  
end