module CustomIssuesHelper
  
  # detects if the current status of the issue is the default one
  def self.is_default_status?(issue)
    if Redmine::VERSION.to_s[0] == "2"
      return issue.status.is_default
    else
      return issue.tracker.default_status_id == issue.status.id
    end
  end
  
end