require File.expand_path('../../test_helper', __FILE__)

class IssueStatusActionsTest < ActiveSupport::TestCase
  
  self.use_instantiated_fixtures = true
  self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
  fixtures :issue_statuses
  
  test "it should reference an action to two issue statuses" do
    action = IssueStatusActions.new(:lib => 'test', :status_id_from => 1, :status_id_to => 2)
    action.save
    assert_not_nil action.status_from
    assert_not_nil action.status_to
  end
  
  test "it should link an action to two issue statuses objects" do
    
    status1 = IssueStatus.find(1)
    status2 = IssueStatus.find(2)
    
    action = IssueStatusActions.new(:lib => 'test', :status_from => status1, :status_to => status2)
    action.save
    
    assert_not_nil action.status_from
    assert_not_nil action.status_to
    assert_not_nil action.status_id_from
    assert_not_nil action.status_id_to
    
  end
  
  test "it should not create an action with identical statuses" do
    
    status1 = IssueStatus.find(1)
    action = IssueStatusActions.new(:lib => 'test', :status_from => status1, :status_to => status1)
    
    assert !action.valid?
    
  end
  
  test "it should not create an action without a status" do
    
    status1 = IssueStatus.find(1)
    action = IssueStatusActions.new(:lib => 'test', :status_from => status1, :status_to => nil)
    
    assert !action.valid?
    
  end
  
  test "it should return the list of actions that are available for a specific issue" do
    
    actions = [
      IssueStatusActions.new(:lib => 'test', :status_from => IssueStatus.find(1), :status_to => IssueStatus.find(2)),
      IssueStatusActions.new(:lib => 'test', :status_from => IssueStatus.find(2), :status_to => IssueStatus.find(3)),
      IssueStatusActions.new(:lib => 'test', :status_from => IssueStatus.find(3), :status_to => IssueStatus.find(4)),
      IssueStatusActions.new(:lib => 'test', :status_from => IssueStatus.find(2), :status_to => IssueStatus.find(4))
    ]
    
    actions.each { |action| action.save }
    
    issue = mock()
    issue.expects(:status).returns(IssueStatus.find(2))
    issue.expects(:new_statuses_allowed_to).returns([IssueStatus.find(1), IssueStatus.find(3)])
    
    available_actions = IssueStatusActions.available_actions(issue)
    
    assert_equal 1, available_actions.count
    assert_equal actions[1], available_actions[0]
    
  end
  
  test "it should change the status of an issue when the action is ran" do
    
    current_status = IssueStatus.find(1)
    target_status = IssueStatus.find(2)
    
    action = IssueStatusActions.new(:lib => 'test', :status_from => current_status, :status_to => target_status)
    action.save
    
    issue = mock()
    issue.expects(:status).returns(current_status)
    issue.expects(:new_statuses_allowed_to).returns([target_status, IssueStatus.find(3)])
    
    issue.expects(:init_journal)
    issue.expects(:status=).with(target_status)
    issue.expects(:save)
    
    AutocloseIssuePatch::AutocloseIssueHook.stubs(:run).with(issue).returns(nil)
    #Redmine::Hook.stubs(:call_hook).returns(nil)
    
    action.run issue
    
  end
  
  test "it should not change the status if the target status of the action is not allowed for this issue" do
    
    current_status = IssueStatus.find(1)
    target_status = IssueStatus.find(2)
    
    action = IssueStatusActions.new(:lib => 'test', :status_from => current_status, :status_to => target_status)
    action.save
    
    issue = mock()
    issue.expects(:status).returns(current_status)
    issue.expects(:new_statuses_allowed_to).returns([IssueStatus.find(3)])
    
    action.run issue
    
  end
  
  test "it should not change the status if the current status of the issue does not match the origin status of the action" do
    
    current_status = IssueStatus.find(1)
    target_status = IssueStatus.find(2)
    
    action = IssueStatusActions.new(:lib => 'test', :status_from => current_status, :status_to => target_status)
    action.save
    
    issue = mock()
    issue.expects(:status).returns(IssueStatus.find(3))
    issue.expects(:new_statuses_allowed_to).returns([target_status])
    
    action.run issue
    
  end
   
end
