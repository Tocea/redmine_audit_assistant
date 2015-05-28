require File.expand_path('../../test_helper', __FILE__)

class ProgressReportControllerTest < ActionController::TestCase
  
  self.use_instantiated_fixtures = true
  self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
  fixtures :projects
  fixtures :issue_categories
  fixtures :issue_statuses
  fixtures :issues
  fixtures :trackers
  fixtures :users
  fixtures :enumerations
  fixtures :roles
  fixtures :members
  fixtures :member_roles
  
  setup do
    @request.session[:user_id] = 1    # admin user
    Project.find(1).enabled_module_names = [:progress_report]
  end
  
  test "it should load the index page" do
    
    get :index, { 'project_id' => 1}
    assert_response :success
    
  end
  
  test "it should load the index page with a version id" do
    
    version = Version.new(
      :project_id => 1, 
      :name => 'Version 1.0 (with bugs)',
      :effective_date => Date.today
    )
    version.save
    
    issue = Issue.find(1)
    issue.fixed_version_id = version.id
    issue.start_date = Date.today
    issue.save
        
    get :index, { 'project_id' => 1, 'version_id' => version.id }
    assert_response :success
    
  end
  
  test "it should redirect to an empty page if the project has not started yet" do
    
    version = Version.new(
      :project_id => 1, 
      :name => 'Version 1.0 (with bugs)',
      :effective_date => Date.today
    )
    version.save
        
    get :index, { 'project_id' => 1, 'version_id' => version.id }
    assert_redirected_to :controller => 'progress_report', :action => 'empty', :project_id => version.project_id
    
  end
  
  test "it should generate a report" do
    
    get :generate, { 'project_id' => 1, 'period' => Date.today }
    assert_response :success
    
  end
  
  test "it should generate a report from a project version" do
    
    version = Version.new(
      :project_id => 1, 
      :name => 'Version 1.0 (with bugs)',
      :effective_date => Date.today
    )
    version.save
    
    issue = Issue.find(1)
    issue.fixed_version_id = version.id
    issue.start_date = Date.today
    issue.save
    
    get :generate, { 'project_id' => 1, 'period' => Date.today, 'version_id' => version.id }
    assert_response :success
    
  end
  
  test "it should generate a report with member occupation parameter" do
    
    get :generate, { 'project_id' => 1, 'period' => Date.today, 'member_occupation' =>  { '1' => '90'} }
    assert_response :success
    
  end
  
  test "it should generate a report with a selection of issues" do
    
    issue = Issue.where(project_id: 1).first
        
    get :generate, { 'project_id' => 1, 'period' => Date.today, 'issues_ids' =>  [issue.id] }
    assert_response :success
    
  end
  
end
