require File.expand_path('../../test_helper', __FILE__)

class ProgressReportTest < ActiveSupport::TestCase
  
  setup do
    @date_from = "2005-01-01".to_date
    @date_to = 10.year.from_now.to_date
  end
  
  test "it should calculate the effective charge" do
    
    project = mock()
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    issues = [
      Issue.new(:estimated_hours => 10),
      Issue.new(:estimated_hours => 15),
      Issue.new(:estimated_hours => 5)
    ]
    
    report.stubs(:issues).returns(issues)
    
    assert_equal 30, report.charge_effective
    
  end
  
  test "it should calculate an estimated charge with a percentage occupation per person" do
    
    project = mock()
    
    occupation_persons = {'1' => '10', '2' => '50' }
    
    report = ProgressReport.new(project, @date_from, @date_to, occupation_persons)
    
    issues = [
      Issue.new(:assigned_to_id => 1, :estimated_hours => 10),  # => 100
      Issue.new(:assigned_to_id => 2, :estimated_hours => 15),  # => 30
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5)    # => 5
    ]
    
    report.stubs(:issues).returns(issues)
    
    assert_equal 135.0, report.charge_estimated
    
  end
  
  test "it should calculated the total charge left with a percentage occupation per person" do
    
    project = mock()
    
    occupation_persons = {'1' => '10', '2' => '50' }
    
    report = ProgressReport.new(project, @date_from, @date_to, occupation_persons)
    
    issues = [
      Issue.new(:assigned_to_id => 1, :estimated_hours => 10, :done_ratio => 20),  # => 8 left   => 80
      Issue.new(:assigned_to_id => 2, :estimated_hours => 30, :done_ratio => 40),  # => 18 left  => 36
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5,  :done_ratio => 0)    # => 5 left   => 5
    ]
    
    status = mock()
    status.expects(:is_closed?).at_least_once.returns(false)
    Issue.any_instance.stubs(:status).returns(status)
    
    report.stubs(:issues).returns(issues)
    
    assert_equal 121.0, report.charge_left
    
  end
  
  test "it should calculated the total charge left" do
    
    project = mock()
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    issues = [
      Issue.new(:assigned_to_id => 1, :estimated_hours => 10, :done_ratio => 20),  # => 8 left
      Issue.new(:assigned_to_id => 2, :estimated_hours => 30, :done_ratio => 40),  # => 18 left
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5,  :done_ratio => 0)    # => 5 left
    ]
    
    status = mock()
    status.expects(:is_closed?).at_least_once.returns(false)
    Issue.any_instance.stubs(:status).returns(status)
    
    report.stubs(:issues).returns(issues)  
    
    assert_equal 31, report.charge_left
    
  end
  
  test "it should ignore the closed issues when calculating the total charge left" do
    
    project = mock()
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    issues = [
      Issue.new(:assigned_to_id => 1, :estimated_hours => 10, :done_ratio => 20),  # => 8 left
      Issue.new(:assigned_to_id => 2, :estimated_hours => 30, :done_ratio => 40),  # => 18 left
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5,  :done_ratio => 0)    # => 5 left
    ]
    
    open = mock()
    open.expects(:is_closed?).at_least_once.returns(false)
    closed = mock()
    closed.expects(:is_closed?).at_least_once.returns(true)
    
    issues[0].stubs(:status).returns(open)
    issues[1].stubs(:status).returns(open)
    issues[2].stubs(:status).returns(closed)
    
    report.stubs(:issues).returns(issues)  
    
    assert_equal 26, report.charge_left
    
  end
  
  test "it should calculate an estimated date for the end of the project/version" do
    
    project = mock()
    
    report = ProgressReport.new(project, "2015-05-18".to_date, "2015-05-22".to_date)
    
    issues = [
      Issue.new(:assigned_to_id => 1, :estimated_hours => 10),  # => 8 left
      Issue.new(:assigned_to_id => 2, :estimated_hours => 30),  # => 18 left
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5)    # => 5 left
    ]
    
    status = mock()
    status.expects(:is_closed?).at_least_once.returns(false)
    Issue.any_instance.stubs(:status).returns(status)
    
    report.stubs(:issues).returns(issues)  
    
    assert_equal "2015-06-01".to_date, report.date_estimated
    
  end
  
  test "it should be possible to create a ProgressReport instance without specifying the date_from" do
    
    project = mock()
    
    date_from = 3.day.ago
    
    ProgressReport.any_instance.stubs(:date_beginning).returns(date_from)
    
    report = ProgressReport.new(project, nil, nil)
    
    assert_equal date_from, report.date_from
    
  end
  
  test "the date_to parameter should be calculated automatically if it is not specified" do
    
    project = mock()
    
    date_from = "2015-05-18".to_date
    date_to = "2015-05-22".to_date
    
    report = ProgressReport.new(project, date_from, nil)
    
    assert_equal date_to, report.date_to.to_date
    
  end
  
  test "it should return all the weeks in the project/version" do
    
    project = mock()
    
    date_from = "2015-05-01".to_date
    date_to = "2015-05-13".to_date

    Time.stubs(:now).returns(Time.parse(date_to.to_s))
    
    ProgressReport.any_instance.stubs(:date_beginning).returns(date_from)
    
    report = ProgressReport.new(project, date_from, nil)

    periods = report.get_week_periods
    puts periods.to_s
    
    assert_equal 3, periods.count
    assert_equal "2015-05-11".to_date, periods[0][0].to_date
    assert_equal "2015-05-15".to_date, periods[0][1].to_date
    
  end
  
  test "it should returns all the users concerned by the report" do
    
    project = mock()
    
    report = ProgressReport.new(project, Date.today, nil)
    
    user1 = mock()
    user2 = mock()
    
    issue1 = mock()
    issue1.expects(:assigned_to).returns(user1)
    
    issue2 = mock()
    issue2.expects(:assigned_to).returns(user1)

    issue3 = mock()
    issue3.expects(:assigned_to).returns(user2)
    
    issue4 = mock()
    issue4.expects(:assigned_to).returns(nil)
    
    ProgressReport.any_instance.stubs(:issues).returns([issue1, issue2, issue3, issue4])
    
    users_found = report.users
    
    # it should not return the same user multiple times
    # it should not return a nil value
    assert_equal 2, users_found.count
    assert users_found.include? user1
    assert users_found.include? user2
    
  end

end