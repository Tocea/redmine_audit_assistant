require File.expand_path('../../test_helper', __FILE__)

class ImportControllerTest < ActionController::TestCase
  
  self.use_instantiated_fixtures = true
  self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
  fixtures :projects
  fixtures :issue_categories
  fixtures :issue_statuses
  fixtures :issues
  fixtures :trackers
  fixtures :users
  fixtures :enumerations
  
  def create_attachment(location, token='X')
    
    diskfile = self.fixture_path+'/files/'+location
    
    # give the file 'diskfile' when an attachment is needed
    attach = mock()
    attach.expects(:diskfile).returns(diskfile)
    Attachment.expects(:find_by_token).with(token).returns(attach)
    
    { :diskfile => diskfile, :token => token }
    
  end
  
  test "should get index" do   
    
    get :index, {'project_id' => 1}
    assert_response :success
    
  end
  
  test "should redirect to index if no attachment has been uploaded" do   
    
    get :import, {'project_id' => 1}
    assert_redirected_to :controller => 'import', :action => 'index', :project_id => 1
    
  end
  
  test "should import requirements from file and redirect to the issue page" do
    
    file = create_attachment('meth_dgac.yml')   
   
    # get the maximum value of the column 'id' in table 'issues'
    max_id = Issue.maximum(:id)
   
    # make the request
    get :import, {'project_id' => 1, 'attachments' => { "1"=>{"filename"=>file[:diskfile], "token"=>file[:token]}} }
    
    # requirements should have been created
    assert Requirement.count > 0  
    
    # look for the root issue
    issue = Issue.where("id > ?", max_id).order(:id).first
    assert_not_nil issue
    
    # we should have been redirected to the root issue page
    assert_redirected_to :controller => 'issues', :action => 'show', :id => issue.id
    
  end
  
  test "should create a version in the project if a version is defined in the file" do
    
    file = create_attachment('meth_dgac_with_version.yml')   
 
    # a new version should have been created
    assert_difference 'Version.count' do
      # make the request
      get :import, {'project_id' => 1, 'attachments' => { "1"=>{"filename"=>file[:diskfile], "token"=>file[:token]}} }
    end
    
  end
  
  test "should not create a new version if the version defined in the file already exists" do
    
    file = create_attachment('meth_dgac_with_version.yml')
    
    version = Version.new(:project_id => 1, :name => 'Audit DGAC')
    version.save
    
    assert_no_difference 'Version.count', 'a version should not be created' do
      get :import, {'project_id' => 1, 'attachments' => { "1"=>{"filename"=>file[:diskfile], "token"=>file[:token]}} }
    end
    
  end
  
  test "should use a version of a project if an id version is set in the parameters" do
    
    file = create_attachment('meth_dgac.yml')
    
    version = Version.new(:project_id => 1, :name => 'Audit DGAC')
    version.save
    
    # there should be more issues attach to this version
    assert_difference 'Issue.where(fixed_version_id: version.id).count', 4 do
      # make the request
      get :import, {'project_id' => 1, 'version_id' => version.id, 'attachments' => { "1"=>{"filename"=>file[:diskfile], "token"=>file[:token]}} }
    end
    
  end
  
  test "should redirect to index if the file cannot be parsed" do
    
    file = create_attachment('file_not_found.yml')
    
    # make the request
    get :import, {'project_id' => 1, 'attachments' => { "1"=>{"filename"=>file[:diskfile], "token"=>file[:token]}} }
    
    # we should have been redirected to the index page
    assert_redirected_to :controller => 'import', :action => 'index', :project_id => 1, :error_parsing_file => true
    
  end
  
end
