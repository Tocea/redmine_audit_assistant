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
      Issue.new(:assigned_to_id => 1, :estimated_hours => 10),  # => +1
      Issue.new(:assigned_to_id => 2, :estimated_hours => 15),  # => +7.5
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5)    # => +0
    ]
    
    report.stubs(:issues).returns(issues)
    
    assert_equal 38.5, report.charge_estimated
    
  end
  
  test "it should calculated the total charge left with a percentage occupation per person" do
    
    project = mock()
    
    occupation_persons = {'1' => '10', '2' => '50' }
    
    report = ProgressReport.new(project, @date_from, @date_to, occupation_persons)
    
    issues = [
      Issue.new(:assigned_to_id => 1, :estimated_hours => 10, :done_ratio => 20),  # => 8 left   => +0.8
      Issue.new(:assigned_to_id => 2, :estimated_hours => 30, :done_ratio => 40),  # => 18 left  => +9
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5,  :done_ratio => 0)    # => 5 left   => +0
    ]
    
    status = mock()
    status.expects(:is_closed?).at_least_once.returns(false)
    Issue.any_instance.stubs(:status).returns(status)
    
    report.stubs(:issues).returns(issues)
    
    assert_equal 40.8, report.charge_left
    
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

end