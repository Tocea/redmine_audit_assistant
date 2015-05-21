class ProjectProgressReport < ProgressReport
    
  def issues
    issues_list = Issue.where(project_id: @root.id)
    issues_list.map { |issue| restore_issue_state(issue, @date_from, @date_to) }
  end
  
  def versions
    Version.where(project_id: @root.id)
  end
  
  def date_effective
    vArr = versions
    if vArr.blank?
      return super
    end   
    vArr.map { |v| v.effective_date }.max
  end
  
end