require File.expand_path('../../test_helper', __FILE__)

class PeriodProgressReportTest < ActiveSupport::TestCase
  
  test "it should return all the weeks in the project/version" do

    date_from = "2015-05-01".to_date
    date_to = "2015-05-13".to_date

    Time.stubs(:now).returns(Time.parse(date_to.to_s))
    
    periods = PeriodProgressReport.week_periods(date_from)
    
    assert_equal 3, periods.count
    assert_equal "2015-05-11".to_date, periods[0].date_from.to_date
    assert_equal "2015-05-15".to_date, periods[0].date_to.to_date
    
  end
  
end