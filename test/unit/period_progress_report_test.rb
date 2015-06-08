require File.expand_path('../../test_helper', __FILE__)

class PeriodProgressReportTest < ActiveSupport::TestCase
  
  test "it should return all the weeks in the project/version" do

    date_from = "2015-05-01".to_date
    date_to = "2015-05-13".to_date

    Time.stubs(:now).returns(Time.parse(date_to.to_s))
    Date.stubs(:today).returns(date_to)
    
    periods = PeriodProgressReport.week_periods(date_from)
    
    assert_equal 3, periods.count
    assert_equal "2015-05-11".to_date, periods[0].date_from.to_date
    assert_equal "2015-05-15".to_date, periods[0].date_to.to_date
    
  end
  
  test "it should set the end of period to the end of the week" do
    
    date_from = "2015-06-01".to_date
    date_to = "2015-06-05".to_date
    
    period = PeriodProgressReport.new(date_from, nil).to_end_of_week
    
    assert_equal date_to, period.date_to.to_date
    
  end
  
end