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
  
  test "should get index" do   
    
    get :index, {'project_id' => 1}
    assert_response :success
    
  end
  
  test "should redirect to index if no attachment has been uploaded" do   
    
    get :import, {'project_id' => 1}
    assert_redirected_to :controller => 'import', :action => 'index', :project_id => 1
    
  end
  
  test "should import requirements from file and redirect to the issue page" do
    
    diskfile = self.fixture_path+"/meth_dgac.yml"
    token = 'X'
    
    # give the file meth_dgac.yml when an attachment is needed
    attach = mock()
    attach.expects(:diskfile).returns(diskfile)
    Attachment.expects(:find_by_token).with(token).returns(attach)
   
    # get the maximum value of the column 'id' in table 'issues'
    max_id = Issue.maximum(:id)
   
    # make the request
    get :import, {'project_id' => 1, 'attachments' => { "1"=>{"filename"=>diskfile, "token"=>token}} }
    
    # requirements should have been created
    assert Requirement.count > 0  
    
    # look for the root issue
    issue = Issue.where("id > ?", max_id).order(:id).first
    assert_not_nil issue
    
    # we should have been redirected to the root issue page
    assert_redirected_to :controller => 'issues', :action => 'show', :id => issue.id
    
  end
  
  test "should redirect to index if the file cannot be parsed" do
    
    diskfile = self.fixture_path+"/file_not_found.yml"
    token = 'X'
    
    # give the file meth_dgac.yml when an attachment is needed
    attach = mock()
    attach.expects(:diskfile).returns(diskfile)
    Attachment.expects(:find_by_token).with(token).returns(attach)
    
    # make the request
    get :import, {'project_id' => 1, 'attachments' => { "1"=>{"filename"=>diskfile, "token"=>token}} }
    
    # we should have been redirected to the index page
    assert_redirected_to :controller => 'import', :action => 'index', :project_id => 1, :error_parsing_file => true
    
  end
  
end
