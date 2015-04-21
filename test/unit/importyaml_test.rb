require File.expand_path('../../test_helper', __FILE__)

class ImportYamlTest < ActiveSupport::TestCase

  self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
  fixtures :projects
  
  setup do
    @helper = Object.new
    @helper.extend(ImportHelper)
  end

  test "it should extract requirement objects from the YAML file" do
    
    file_location = fixture_path + '/meth_dgac.yml'
    
    results = @helper.import_from_yaml(file_location)
    
    assert_not_nil results, "it should return something"
    assert_not_nil results[:requirements], "it should return requirement objects"
    
    requirements = results[:requirements]
    
    assert_equal 1, requirements.count
    assert_equal 2, requirements[0].children.count
    assert_equal 0, requirements[0].children[0].children.count
    assert_equal 1, requirements[0].children[1].children.count
    
  end
  
  test "it should extract the version data from the YAML file" do
    
    file_location = fixture_path + '/meth_dgac_with_version.yml'
    
    results = @helper.import_from_yaml(file_location)
    
    assert_not_nil results, "it should return something"
    assert_not_nil results[:version], "it should return a version"
    assert_not_nil results[:version].name, "the version name should have been set"
    assert_not_nil results[:version].effective_date, "the version date should have been set"
    assert_kind_of Date, results[:version].effective_date, "the version date should be a Date instance"
    
  end
  
  test "it should extract requirement dates from the YAML file" do
    
    file_location = fixture_path + '/meth_dgac_with_dates.yml'
    
    results = @helper.import_from_yaml(file_location)
    
    assert_not_nil results, "it should return something"
    assert_not_nil results[:requirements], "it should return requirement objects"
    assert_kind_of Date, results[:requirements][0].start_date, "the start date should be a Date instance"
    assert_kind_of Date, results[:requirements][0].effective_date, "the effective date should be a Date instance"
    
  end
  
  test "it should extract requirement priority from the YAML file" do
    
    file_location = fixture_path + '/meth_dgac_with_priority.yml'
    
    results = @helper.import_from_yaml(file_location)
    
    assert_not_nil results, "it should return something"
    assert_not_nil results[:requirements], "it should return requirement objects"
    assert_not_nil results[:requirements][0].priority_id, "the priority should have been set" 
    
  end
  
  test "it should extract requirement categories from the YAML file" do
    
    file_location = fixture_path + '/meth_dgac_with_category.yml'
    
    results = @helper.import_from_yaml(file_location)
    
    assert_not_nil results, "it should return something"
    assert_not_nil results[:requirements], "it should return requirement objects"
    assert_not_nil results[:requirements][0].issue_category_name, "the category name should have been set" 
    
  end
  
  test "it should extract a checklist from the YAML file" do
    
    file_location = fixture_path + '/meth_dgac_with_checklist.yml'
    
    results = @helper.import_from_yaml(file_location)
    
    assert_not_nil results, "it should return something"
    assert_not_nil results[:requirements], "it should return requirement objects"
    assert_not_nil results[:requirements][0].checklist, "the checklist should not be nil"
    assert_equal 3, results[:requirements][0].checklist.length, "the checklist should contain 3 items"
    
  end

end