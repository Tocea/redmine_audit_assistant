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
  
  test "it should generate a report even if there is an incorrect value in the member occupation parameter" do
    
    get :generate, { 'project_id' => 1, 'period' => Date.today, 'member_occupation' =>  { '1' => 'H'} }
    assert_response :success
    
  end
  
  test "it should generate a report with a selection of issues" do
    
    issue = Issue.where(project_id: 1).first
        
    get :generate, { 'project_id' => 1, 'period' => Date.today, 'issues_ids' =>  [issue.id] }
    assert_response :success
    
  end
  
  test "it should generate a report with time_switching_issues parameter" do
    
    get :generate, { 'project_id' => 1, 'period' => Date.today, 'time_switching_issues' =>  '50' }
    assert_response :success
    
  end
  
  test "it should generate a report with days_off parameter" do
    
    get :generate, { 'project_id' => 1, 'period' => Date.today, 'days_off' =>  { '1' => '5' } }
    assert_response :success
    
  end
  
  test "it should save the generated report" do
    
    assert_difference "Attachment.count" do
      get :generate, { 'project_id' => 1, 'period' => Date.today }
    end
    
    attachment = Attachment.find(1)
    assert_equal 'Project', attachment.container_type
    assert_equal 1, attachment.container_id
    
  end
  
  test "it should save only one report per week" do
    
    assert_difference "Attachment.count" do
      get :generate, { 'project_id' => 1, 'period' => Date.today }
    end
    
    assert_no_difference "Attachment.count" do
      get :generate, { 'project_id' => 1, 'period' => Date.today }
    end
    
  end
  
  test "it should not delete the report of the previous week" do
    
    date_previous_attachment = 7.day.ago
    
    attachment = Attachment.new
    attachment.container_type = 'Project'
    attachment.container_id = 1
    attachment.filename = 'Report.html'
    attachment.created_on = date_previous_attachment
    attachment.save
    
    assert_equal date_previous_attachment.to_date, attachment.created_on.to_date
    
    assert_difference "Attachment.count" do
      get :generate, { 'project_id' => 1, 'period' => Date.today }
    end

  end
  
  test "it should retrieve the last generated report" do
    
    # generate a report
    get :generate, { 'project_id' => 1, 'period' => Date.today }
    
    # access the generated report
    get :last_report, { 'project_id' => 1 }

    attachment = Attachment.all[0]

    assert_redirected_to :controller => 'attachments', :action => 'download', :id => attachment.id
    
  end
  
  test "it should redirect to the index page if there is no generated report" do
    
    get :last_report, { 'project_id' => 1 }
    assert_redirected_to :controller => 'progress_report', :action => 'index', :project_id => 1
    
  end
  
  test "it should retrieve the last generated report of a version" do
    
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
    
    # generate a report
    get :generate, { 'project_id' => 1, 'period' => Date.today, 'version_id' => version.id }
    
    # access the generated report
    get :last_report, { 'project_id' => 1, 'version_id' => version.name }
    
    attachment = Attachment.all[0]

    assert_redirected_to :controller => 'attachments', :action => 'download', :id => attachment.id
    
  end
  
end
