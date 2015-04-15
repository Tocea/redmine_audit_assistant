require File.expand_path('../../test_helper', __FILE__)

class ImportYamlTest < ActiveSupport::TestCase

  self.fixture_path = File.dirname(__FILE__) + '/../fixtures'

  setup do
    @helper = Object.new
    @helper.extend(ImportHelper)
  end

  test "it should extract requirement objects from the YAML file" do
    
    file_location = fixture_path + '/meth_dgac.yml'
    
    requirements = @helper.import_from_yaml(file_location)
    puts requirements.inspect
    
    Requirement.find(:all).each do |r|
      puts r.inspect
    end
    
    assert_equal 4, Requirement.count
    assert_equal 1, requirements.count
    assert_equal 2, requirements[0].children.count
    assert_equal 0, requirements[0].children[0].children.count
    assert_equal 1, requirements[0].children[1].children.count
    
  end

end