class ProjectProgressReport < ProgressReport
    
  def issues
    issues_list = Issue.where(project_id: @root.id)
    restore_issues_states(issues_list, @date_from, @date_to)
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