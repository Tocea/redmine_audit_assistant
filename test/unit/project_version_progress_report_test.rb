require File.expand_path('../../test_helper', __FILE__)

class ProjectVersionProgressReportTest < ActiveSupport::TestCase
  
  self.use_instantiated_fixtures = true
  self.fixture_path = File.dirname(__FILE__) + '/../fixtures'
  fixtures :projects
  fixtures :issue_statuses
  fixtures :issues
  fixtures :users
  fixtures :enumerations
  fixtures :journals
  fixtures :journal_details
  fixtures :versions
  
  setup do
    @date_from = "2005-01-01".to_date
    @date_to = 10.year.from_now.to_date
    @period = PeriodProgressReport.new(@date_from, @date_to)
  end
  
  test "it should return the issues of the version" do
    
    version = Version.find(8)
    
    issues = Issue.where(fixed_version_id: version.id)
    
    report = ProjectVersionProgressReport.new(version, @period)
    
    assert_equal issues.count, report.issues.count
    
  end
  
  test "it should return the date of beginning of the version" do
    
    version = Version.find(8)
    
    report = ProjectVersionProgressReport.new(version, @period)
    
    assert_equal 3.day.ago.to_date, report.date_beginning.to_date
    
  end
  
  
  test "the due date of the version should its effective date" do
    
    version = Version.find(8)
    
    report = ProjectVersionProgressReport.new(version, @period)
    
    assert_equal version.effective_date, report.date_effective
    
  end
  

end