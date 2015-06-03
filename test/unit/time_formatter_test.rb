require File.expand_path('../../test_helper', __FILE__)

class TimeFormatterTest < ActiveSupport::TestCase
  
  test "it should convert hours to days" do
    
    nb_hours_per_day = 5.00
    hours = 20.00
    
    formatter = TimeFormatter.new(nb_hours_per_day)
    
    assert_equal hours / nb_hours_per_day, formatter.format_hours(hours, 'd')
    
  end
  
  test "it should convert days to hours" do
    
    nb_hours_per_day = 5.00
    days = 20.00
    
    formatter = TimeFormatter.new(nb_hours_per_day)
    
    assert_equal days * nb_hours_per_day, formatter.format_days(days, 'h')
    
  end
  
end