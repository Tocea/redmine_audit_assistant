require File.expand_path('../../test_helper', __FILE__)

class ProjectProgressReportTest < ActiveSupport::TestCase
  
  self.use_instantiated_fixtures = true
  self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
  fixtures :projects
  fixtures :issue_statuses
  fixtures :issues
  fixtures :users
  fixtures :enumerations
  fixtures :journals
  fixtures :journal_details
  
  setup do
    @date_from = "2005-01-01".to_date
    @date_to = 10.year.from_now.to_date
    @period = PeriodProgressReport.new(@date_from, @date_to)
  end
  
  test "it should return the issues of the project" do
    
    project = Project.find(1)
    
    issues = Issue.where(project_id: project.id)
    
    report = ProjectProgressReport.new(project, @period)
    
    assert_equal issues.count, report.issues.count
    
  end
  
  test "it should return the date of beginning of the project" do
    
    project = Project.find(1)
    
    report = ProjectProgressReport.new(project, @period)
    
    assert_equal 3.day.ago.to_date, report.date_beginning.to_date
    
  end
  
  test "the due date of the project should be the last effective dates of its versions" do
    
    project = Project.find(1)
    
    version1 = Version.new(
      :name => 'Version 1.0',
      :project_id => project.id,
      :effective_date => 3.month.from_now.to_date
    )
    version1.save
    
    version2 = Version.new(
      :name => 'Version 2.0',
      :project_id => project.id,
      :effective_date => 5.month.from_now.to_date
    )
    version2.save
    
    version3 = Version.new(
      :name => 'Version 3.0',
      :project_id => project.id,
      :effective_date => 2.month.from_now.to_date
    )
    version3.save
    
    report = ProjectProgressReport.new(project, @period)
    
    assert_equal version2.effective_date, report.date_effective
    
  end
  
  test "the due date should of the project should be the last due date of its issues if there is no version" do
    
    project = Project.find(1)
    
    issues = Issue.where(project_id: project.id)
    
    assert_not_equal 0, issues.count
    
    max_due_date = issues.map { |issue| issue.due_date }.max
    
    report = ProjectProgressReport.new(project, @period)
    
    assert_equal max_due_date, report.date_effective
    
  end
  
  test "it should retrieve the issues that have changed during a particular period" do
    
    project = Project.find(1)
    
    date_from = "2015-04-01".to_date
    date_to = "2015-04-30".to_date
    
    report = ProjectProgressReport.new(project, @period)
    
    assert_equal 1, report.issues_updated.count
    
  end
  
  test "it should not failed when trying to access the initial charge of a project" do
    
    report = ProjectProgressReport.new(mock(), @period)
    
    assert_equal 0.00, report.charge_initial('d')
    
  end

end