class ProjectVersionProgressReport < ProgressReport
  
  def issues
    issues_list = Issue.where(fixed_version_id: @root.id)
    restore_issues_states(issues_list, @date_from, @date_to)
  end
  
  def date_effective
    @root.effective_date
  end
  
end