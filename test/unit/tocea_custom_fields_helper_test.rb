require File.expand_path('../../test_helper', __FILE__)

class ToceaCustomFieldsHelperTest < ActiveSupport::TestCase
  
  setup do
    @helper = Object.new
    @helper.extend(ToceaCustomFieldsHelper)
  end
  
  test "it should try to retrieve the custom field value of a code project on a project instance" do
    
    field_id = 1
    field_value = "test"
    
    field = mock()
    field.expects(:id).returns(field_id)
    
    project = mock()
    project.expects(:custom_value_for).with(field_id).returns(field_value)
    
    ProjectCustomField.stubs(:find_by_name).returns(field)

    assert_equal field_value, @helper.code_project(project)
    
  end
  
  test "it should not fail when the project custom field of a code project does not exist" do
    
    project = mock()
    
    ProjectCustomField.stubs(:find_by_name).returns(nil)

    assert @helper.code_project(project).nil?
    
  end
  
  test "it should try to retrieve the custom field value of a code project on a version instance" do
    
    field_id = 1
    field_value = "test"
    
    field = mock()
    field.expects(:id).returns(field_id)
    
    version = mock()
    version.expects(:custom_value_for).with(field_id).returns(field_value)
    
    VersionCustomField.stubs(:find_by_name).returns(field)

    assert_equal field_value, @helper.code_version(version)
    
  end
  
  test "it should not fail when the version custom field of a code project does not exist" do
    
    version = mock()
    
    VersionCustomField.stubs(:find_by_name).returns(nil)

    assert @helper.code_version(version).nil?
    
  end
  
end