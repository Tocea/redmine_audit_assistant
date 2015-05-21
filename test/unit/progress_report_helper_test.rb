require File.expand_path('../../test_helper', __FILE__)

class ProgressReportHelperTest < ActiveSupport::TestCase
  
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
    @helper = Object.new
    @helper.extend(ProgressReportHelper)
  end
  
  
  test "it should restore the issue to its previous state" do
    
    issue = Issue.find(1)
    
    assert_not_equal 99, issue.done_ratio
    
    issue.done_ratio = 99
    issue.save
    
    assert_equal 99, issue.done_ratio
    
    previous_issue_version = @helper.restore_issue_state(issue, "2015-04-01".to_date, "2015-04-30".to_date)
    
    assert_not_equal 99, previous_issue_version.done_ratio
    
  end
  
  test "it should return a previous version of the issue if no changed has been found during the period" do
    
    issue = Issue.find(1)
    
    issue.done_ratio = 99
    issue.save   
    assert_equal 99, issue.done_ratio
    
    previous_issue_version = @helper.restore_issue_state(issue, Date.parse("2015-03-20"), Date.parse("2015-03-25"))
    
    assert_equal 10, previous_issue_version.done_ratio
    
  end
  
  test "it should not fail if the period is incorrect" do
    
    issues = [Issue.find(1), Issue.find(2), Issue.find(3)]
    date_to = "2015-04-01".to_date
    date_from = "2015-04-30".to_date
    
    assert_equal 0, @helper.get_issues_journals(issues, date_from, date_to).count
    
  end
  
  test "it should not fail if the period is not defined" do
    
    issues = [Issue.find(1), Issue.find(2), Issue.find(3)]
    
    assert_equal 0, @helper.get_issues_journals(issues, nil, nil).count
    
  end
  
  test "it should not fail if the issues are not defined" do
    
    date_to = "2015-04-01".to_date
    date_from = "2015-04-30".to_date
    
    assert_equal 0, @helper.get_issues_journals(nil, date_from, date_to).count
    
  end
  
  test "it should return the journals of given issues during a given period" do
    
    issues = [Issue.find(1), Issue.find(2), Issue.find(3)]
    date_from = "2015-04-01".to_date
    date_to = "2015-04-30".to_date
    
    assert_equal 2, @helper.get_issues_journals(issues, date_from, date_to).count
    
  end
  
end