require File.expand_path('../../test_helper', __FILE__)

class IssuesCustomActionsControllerTest < ActionController::TestCase
  
  self.use_instantiated_fixtures = true
  self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
  fixtures :projects
  fixtures :issue_categories
  fixtures :issue_statuses
  fixtures :issues
  fixtures :trackers
  fixtures :users
  fixtures :enumerations
  
  test "it should create a new status action" do
    
    assert_difference 'IssueStatusActions.count' do
      get :insert, { 'action_lib' => 'test', 'status_from' => 1, 'status_to' => 2 }
    end
    
  end
  
  test "it should not create a new status action if the given statuses do not exist" do
    
    assert_no_difference 'IssueStatusActions.count' do
      get :insert, { 'action_lib' => 'test', 'status_from' => 99, 'status_to' => 98 }
    end
    
  end
  
  test "it should not create a new status action if the status action cannot be validated" do
    
    IssueStatusActions.any_instance.stubs(:valid?).returns(false)
    
    assert_no_difference 'IssueStatusActions.count' do
      get :insert, { 'action_lib' => 'test', 'status_from' => 1, 'status_to' => 2 }
    end
    
  end
  
  test "it should delete an action" do
    
    action = IssueStatusActions.new(
      :lib => 'test', 
      :status_from => IssueStatus.find(1), 
      :status_to => IssueStatus.find(2)
    )
    action.save
    
    assert_not_nil action.id
    
    assert_difference 'IssueStatusActions.count', -1 do
      get :delete, { 'action_id' => action.id }
    end
    
  end
  
  test "it should run a given action on a given issue" do
    
    id = 12
    issue = Issue.find(1)
    
    action = mock()
    action.expects(:run).with(issue)
    
    IssueStatusActions.stubs(:find).with(id.to_s).returns(action)
    
    get :run, { 'action_id' => id.to_s, 'issue_id' => issue.id }
    
  end
  
  test "it should load the settings page" do   
    
    get :settings, {}
    assert_response :success
    
  end
  
end
