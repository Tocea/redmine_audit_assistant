require File.expand_path('../../test_helper', __FILE__)

class ProgressReportTest < ActiveSupport::TestCase
  
  self.use_instantiated_fixtures = true
  self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
  fixtures :projects
  fixtures :issue_statuses
  fixtures :issues
  fixtures :users
  fixtures :enumerations
  
  setup do
    @date_from = "2005-01-01".to_date
    @date_to = 10.year.from_now.to_date
  end
  
  test "it should return the list of issues that are leafs" do
    
    issues = [
      Issue.find(1),    # leaf 
      Issue.find(2),
      Issue.find(3),
      Issue.find(4),
      Issue.find(5),    # leaf
      Issue.find(6)     # leaf
    ]
    
    project = mock()
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    report.stubs(:issues).returns(issues)
    
    leafs = report.leaf_issues
    
    assert_equal 3, leafs.count
    assert leafs.include? issues[0]
    assert leafs.include? issues[4]
    assert leafs.include? issues[5]
    
  end
  
  test "it should calculate the effective charge" do
    
    project = mock()
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    issues = [
      Issue.new(:estimated_hours => 10.00),
      Issue.new(:estimated_hours => 15.00),
      Issue.new(:estimated_hours => 5.00)
    ]
    
    report.stubs(:leaf_issues).returns(issues)
    
    assert_equal 30, report.charge_effective
    
  end
  
  test "it should return the effective charge in days" do
    
    project = mock()
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    issues = [
      Issue.new(:estimated_hours => 10.00),
      Issue.new(:estimated_hours => 15.00),
      Issue.new(:estimated_hours => 5.00)
    ]
    
    report.stubs(:leaf_issues).returns(issues)
    
    assert_equal 4, report.charge_effective('d')
    
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
    
    report.stubs(:leaf_issues).returns(issues)
    
    assert_equal 135.0, report.charge_estimated
    
  end
  
  test "it should calculate the total charge left from the total initial charge" do
    
    project = mock()
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    issues = [
      Issue.new(:assigned_to_id => 1, :estimated_hours => 10, :done_ratio => 20),  # => 2 burnt
      Issue.new(:assigned_to_id => 2, :estimated_hours => 30, :done_ratio => 40),  # => 12 burnt
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5,  :done_ratio => 0)    # => 0 burnt
    ]                                                                              # total burnt: 14
    
    status = mock()
    status.expects(:is_closed?).at_least_once.returns(false)
    Issue.any_instance.stubs(:status).returns(status)
    
    report.stubs(:charge_initial).returns(50)   
    report.stubs(:leaf_issues).returns(issues)  
    
    assert_equal 36, report.charge_left
    
  end
  
  test "it should calculate the total charge left from the total effective charge" do
    
    project = mock()
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    issues = [
      Issue.new(:assigned_to_id => 1, :estimated_hours => 10, :done_ratio => 20),  # => 2 burnt
      Issue.new(:assigned_to_id => 2, :estimated_hours => 30, :done_ratio => 40),  # => 12 burnt
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5,  :done_ratio => 0)    # => 0 burnt
    ]                                                                              # total burnt: 14
    
    status = mock()
    status.expects(:is_closed?).at_least_once.returns(false)
    Issue.any_instance.stubs(:status).returns(status)
    
    report.stubs(:charge_initial).returns(0)
    report.stubs(:charge_effective).returns(20)
    
    report.stubs(:leaf_issues).returns(issues)  
    
    assert_equal 6, report.charge_left
    
  end
  
  test "it should return a negative value if the total charge left is superior to the initial charge" do
    
    project = mock()
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    issues = [
      Issue.new(:assigned_to_id => 1, :estimated_hours => 10, :done_ratio => 20),  # => 2 burnt
      Issue.new(:assigned_to_id => 2, :estimated_hours => 30, :done_ratio => 40),  # => 12 burnt
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5,  :done_ratio => 0)    # => 0 burnt
    ]                                                                              # total burnt: 14
    
    status = mock()
    status.expects(:is_closed?).at_least_once.returns(false)
    Issue.any_instance.stubs(:status).returns(status)
    
    report.stubs(:charge_initial).returns(10)   
    report.stubs(:leaf_issues).returns(issues)  
    
    assert_equal -4, report.charge_left
    
  end
  
  test "it should not ignore the closed issues when calculating the total charge left" do
    
    project = mock()
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    issues = [
      Issue.new(:assigned_to_id => 1, :estimated_hours => 10, :done_ratio => 20),  # => 2 burnt
      Issue.new(:assigned_to_id => 2, :estimated_hours => 30, :done_ratio => 40),  # => 12 burnt
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5,  :done_ratio => 10)   # => 5 burnt
    ]                                                                              # total: 19 burnt   
    
    open = mock()
    open.expects(:is_closed?).at_least_once.returns(false)
    closed = mock()
    closed.expects(:is_closed?).at_least_once.returns(true)
    
    issues[0].stubs(:status).returns(open)
    issues[1].stubs(:status).returns(open)
    issues[2].stubs(:status).returns(closed)
    
    report.stubs(:charge_initial).returns(25) 
    report.stubs(:leaf_issues).returns(issues)  
    
    assert_equal 6, report.charge_left
    
  end
  
  test "it should return the total charge that is not affected to anybody" do
    
    project = mock()
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    issues = [
      Issue.new(:assigned_to_id => nil, :estimated_hours => 10),  
      Issue.new(:assigned_to_id => 2, :estimated_hours => 30), 
      Issue.new(:assigned_to_id => nil, :estimated_hours => 15),   
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5)  
    ]
    
    report.stubs(:leaf_issues).returns(issues)  
    
    assert_equal 25, report.charge_unassigned
    
  end
  
  test "it should calculate an estimated date for the end of the project/version" do
    
    project = mock()
    
    report = ProgressReport.new(project, "2015-05-18".to_date, "2015-05-22".to_date)
    
    users_id = [
      1,   # => 10 days  => 2015-06-06
      2,   # => 8 days   => 2015-06-02
      3    # => 5 days   => 2015-05-29
    ]
    
    users = []
    users_id.each do |id|
      user = mock()
      user.expects(:id).at_least_once.returns(id)  
      users.push(user)
    end
    
    issues = [
      Issue.new(:assigned_to_id => 1, :estimated_hours => 10 * 8),  
      Issue.new(:assigned_to_id => 2, :estimated_hours => 8 * 8),  
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5 * 8)    
    ]
    
    status = mock()
    status.expects(:is_closed?).at_least_once.returns(false)
    Issue.any_instance.stubs(:status).returns(status)
    
    report.stubs(:leaf_issues).returns(issues)  
    report.stubs(:users).returns(users)
    
    assert_equal "2015-06-05".to_date, report.date_estimated
    
  end
  
  test "it should calculate an estimated date for the end of the project with multiple issues to the same person" do
    
    project = mock()
    
    report = ProgressReport.new(project, "2015-05-18".to_date, "2015-05-22".to_date)
    
    id = 1
    user = mock()
    user.expects(:id).at_least_once.returns(id)  
    users = [user]
    
    issues = [
      Issue.new(:assigned_to_id => id, :estimated_hours => 10 * 8),  
      Issue.new(:assigned_to_id => id, :estimated_hours => 8 * 8),  
      Issue.new(:assigned_to_id => id, :estimated_hours => 5 * 8)    
    ]             # => 23 days => 2015-06-24
    
    status = mock()
    status.expects(:is_closed?).at_least_once.returns(false)
    Issue.any_instance.stubs(:status).returns(status)
    
    report.stubs(:leaf_issues).returns(issues)  
    report.stubs(:users).returns(users)
    
    assert_equal "2015-06-24".to_date, report.date_estimated
    
  end
  
  test "it should ignore the closed issues when calculating an estimated date" do
    
    project = mock()
    
    report = ProgressReport.new(project, "2015-05-18".to_date, "2015-05-22".to_date)
    
    id = 1
    user = mock()
    user.expects(:id).at_least_once.returns(id)  
    users = [user]
    
    issues = [
      Issue.new(:assigned_to_id => id, :estimated_hours => 10 * 8),  
      Issue.new(:assigned_to_id => id, :estimated_hours => 8 * 8),  
      Issue.new(:assigned_to_id => id, :estimated_hours => 5 * 8)    
    ]             # => 15 days => 2015-06-12
    
    open = mock()
    open.expects(:is_closed?).at_least_once.returns(false)
    issues[0].stubs(:status).returns(open)
    issues[2].stubs(:status).returns(open)
    
    closed = mock()
    closed.expects(:is_closed?).at_least_once.returns(true)
    issues[1].stubs(:status).returns(closed)
    
    report.stubs(:leaf_issues).returns(issues)  
    report.stubs(:users).returns(users)
    
    assert_equal "2015-06-12".to_date, report.date_estimated
    
  end
  
  test "it should not fail to calculate the estimated date if the issues do not have estimated hours" do
    
    project = mock()
    
    report = ProgressReport.new(project, "2015-05-18".to_date, "2015-05-22".to_date)
    
    id = 1
    user = mock()
    user.expects(:id).at_most_once.returns(id)  
    users = [user]
    
    issues = [
      Issue.new(:assigned_to_id => id, :estimated_hours => nil),  
      Issue.new(:assigned_to_id => id, :estimated_hours => nil),  
      Issue.new(:assigned_to_id => id, :estimated_hours => nil)    
    ]             # => 15 days => 2015-06-12
    
    status = mock()
    status.expects(:is_closed?).at_most(3).returns(false)
    Issue.any_instance.stubs(:status).returns(status)
    
    report.stubs(:leaf_issues).returns(issues)  
    report.stubs(:users).returns(users)
    
    assert_equal "2015-05-22".to_date, report.date_estimated
    
  end
  
  test "it should not fail to calculate the estimated date if the issues are not assigned to anybody" do
    
    project = mock()
    
    report = ProgressReport.new(project, "2015-05-18".to_date, "2015-05-22".to_date)
    
    issues = [
      Issue.new(:assigned_to_id => nil, :estimated_hours => 10 * 8),  
      Issue.new(:assigned_to_id => nil, :estimated_hours => 8 * 8),  
      Issue.new(:assigned_to_id => nil, :estimated_hours => 5 * 8)    
    ]             # => 23 days => 2015-06-24
    
    status = mock()
    status.expects(:is_closed?).at_least_once.returns(false)
    Issue.any_instance.stubs(:status).returns(status)
    
    report.stubs(:leaf_issues).returns(issues)  
    report.stubs(:users).returns([])
    
    assert_equal "2015-06-24".to_date, report.date_estimated
    
  end
  
  test "it should use issues done ratios to calculate the estimated date" do
    
    project = mock()
    
    report = ProgressReport.new(project, "2015-05-18".to_date, "2015-05-22".to_date)
    
    id = 1
    user = mock()
    user.expects(:id).at_least_once.returns(id)  
    users = [user]
    
    issues = [
      Issue.new(:assigned_to_id => id, :estimated_hours => 10 * 8, :done_ratio => 10),  # => 9 days
      Issue.new(:assigned_to_id => id, :estimated_hours => 8 * 8, :done_ratio => 50),   # => 4 days
      Issue.new(:assigned_to_id => id, :estimated_hours => 5 * 8, :done_ratio => 0),    # => 5 days
      Issue.new(:assigned_to_id => id, :estimated_hours => 35 * 8, :done_ratio => 100)  # => 0 days
    ]             # => 18 days => 2015-06-24
    
    status = mock()
    status.expects(:is_closed?).at_least_once.returns(false)
    Issue.any_instance.stubs(:status).returns(status)
    
    report.stubs(:leaf_issues).returns(issues)  
    report.stubs(:users).returns(users)
    
    assert_equal "2015-06-17".to_date, report.date_estimated
    
  end
  
  test "it should use the percentage of occupation per person to calculate the estimated date" do
    
    project = mock()
    occupation_persons = { '1' => '90', '2' => '70' }
    date_from = "2015-05-18".to_date
    date_to = "2015-05-22".to_date
    
    report = ProgressReport.new(project, date_from, date_to, occupation_persons)
    
    users_id = [
      1,   # => 11.11 days  => 2015-06-09
      2,   # => 11.42 days   => 2015-06-09
      3    # => 5 days   => 2015-05-29
    ]
    
    users = []
    users_id.each do |id|
      user = mock()
      user.expects(:id).at_least_once.returns(id)  
      users.push(user)
    end
    
    issues = [
      Issue.new(:assigned_to_id => 1, :estimated_hours => 10 * 8),
      Issue.new(:assigned_to_id => 2, :estimated_hours => 8 * 8),  
      Issue.new(:assigned_to_id => 3, :estimated_hours => 5 * 8)    
    ]
    
    status = mock()
    status.expects(:is_closed?).at_least_once.returns(false)
    Issue.any_instance.stubs(:status).returns(status)
    
    report.stubs(:leaf_issues).returns(issues)  
    report.stubs(:users).returns(users)
    
    assert_equal "2015-06-09".to_date, report.date_estimated
    
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
    
    # it should not return the same user multiple times or a nil value
    assert_equal 2, users_found.count
    assert users_found.include? user1
    assert users_found.include? user2
    
  end
  
  test "it should indicate if a project will be late" do
    
    project = mock()
    date_estimated = Date.today
    date_effective = 2.day.ago
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    report.stubs(:date_estimated).returns(date_estimated)
    report.stubs(:date_effective).returns(date_effective)
    
    assert report.late?
    
  end
  
  test "it should indicate if a project will not be late" do
    
    project = mock()
    date_effective = Date.today
    date_estimated = 2.day.ago
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    report.stubs(:date_estimated).returns(date_estimated)
    report.stubs(:date_effective).returns(date_effective)
    
    assert !report.late?
    
  end
  
  test "it should indicate that the project will not be late if the effective date is not defined" do
    
    project = mock()
    date_effective = nil
    date_estimated = 2.day.ago
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    report.stubs(:date_estimated).returns(date_estimated)
    report.stubs(:date_effective).returns(date_effective)
    
    assert !report.late?
    
  end
  
  test "it should indicate that the project will be late or not by using the current date if the estimated date does not exist" do
    
    project = mock()
    date_effective = 1.day.ago
    date_estimated = nil
    
    report = ProgressReport.new(project, @date_from, @date_to)
    
    report.stubs(:date_estimated).returns(date_estimated)
    report.stubs(:date_effective).returns(date_effective)
    
    assert report.late?
    
  end
  
end