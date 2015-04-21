require File.expand_path('../../test_helper', __FILE__)

class ChecklistHelperTest < ActiveSupport::TestCase
  
  setup do
    @helper = Object.new
    @helper.extend(ChecklistHelper)
  end
  
  test "it should not do anything if there is no checklist in the requirement object" do
    
    issue = mock()
    requirement = Requirement.new(:name => 'the requirement')
    
    assert !@helper.create_issue_checklist(requirement, issue)
    
  end
  
  test "it should not do anything if the Checklist plugin cannot be loaded" do
    
    issue = mock()
    requirement = Requirement.new(
      :name => 'the requirement',
      :checklist => ['item1', 'item2', 'item3']
    )
    
    @helper.expects(:available?).returns(false)
    
    @helper.create_issue_checklist(requirement, issue)
    
  end
  
  test "it should create a checklist using the Redmine Checklist plugin" do
    
    issue = mock()
    requirement = Requirement.new(
      :name => 'the requirement',
      :checklist => ['item1', 'item2']
    )
    
    checklist_from_plugin = mock()
    checklist_from_plugin.expects(:new).with({ :issue => issue, :subject => 'item1'}).returns(checklist_from_plugin)
    checklist_from_plugin.expects(:new).with({ :issue => issue, :subject => 'item2'}).returns(checklist_from_plugin)
    checklist_from_plugin.expects(:save).twice.returns(true)
    
    @helper.expects(:available?).returns(true)
    
    @helper.expects(:checklist_from_plugin).twice.returns(checklist_from_plugin)
    
    @helper.create_issue_checklist(requirement, issue)
    
  end

end