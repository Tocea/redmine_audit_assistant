class ProjectVersionProgressReport < ProgressReport
  
  def issues
    issues_list = Issue.where(fixed_version_id: @root.id)
    issues_list.map { |issue| restore_issue_state(issue, @date_from, @date_to) }
  end
  
  def date_effective
    @root.effective_date
  end
  
end