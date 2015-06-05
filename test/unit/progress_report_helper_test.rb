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
    
    issue.created_on = "2015-04-01".to_date
    issue.done_ratio = 99
    issue.save
    
    assert_equal 99, issue.done_ratio
    
    previous_issue_version = @helper.restore_issue_state(issue, "2015-04-01".to_date, "2015-04-30".to_date)
    
    assert_not_equal 99, previous_issue_version.done_ratio
    
  end
  
  test "it should return a previous version of the issue if no changed has been found during the period" do
    
    issue = Issue.find(1)
    
    issue.created_on = "2015-01-01".to_date
    issue.done_ratio = 99
    issue.save   
    assert_equal 99, issue.done_ratio
    
    previous_issue_version = @helper.restore_issue_state(issue, Date.parse("2015-03-20"), Date.parse("2015-03-25"))
    
    assert_equal 10, previous_issue_version.done_ratio
    
  end
  
  test "it should return nil if the issue did not exist during the given period" do
    
    issue = Issue.find(1)
    
    issue.created_on = "2015-05-01".to_date
    issue.save   
    
    previous_issue_version = @helper.restore_issue_state(issue, Date.parse("2015-03-20"), Date.parse("2015-03-25"))
    
    assert previous_issue_version.nil?
    
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
  
  test "it should call restore a list of issues to their previous states during a given period" do
    
    issues = [mock(), mock(), nil, nil]
    
    date_from = "2015-04-01".to_date
    date_to = "2015-04-30".to_date
    
    issues.each do |issue|
      @helper.stubs(:restore_issue_state).with(issue, date_from, date_to).returns(issue)
    end

    assert_equal 2, @helper.restore_issues_states(issues, date_from, date_to).count
    
  end
  
  test "it should return the journal details associated to Journal objects" do
    
    journals = [Journal.find(1), Journal.find(2), Journal.find(3)]
    
    changelog = @helper.get_journal_details(journals)
    
    assert_equal 3, changelog.count
    
  end
  
end