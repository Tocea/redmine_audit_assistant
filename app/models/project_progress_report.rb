class ProjectProgressReport < ProgressReport
  
  # returns the project's issues
  # in their state during the report's period
  def issues
    if @issues.nil?
      # the function that restore issues to their previous states
      # is very costly, so it must be called only once per report
      @issues = Issue.where(project_id: @root.id)
      @issues = restore_issues_states(@issues, @date_from, @date_to)
    end
    @issues
  end
  
  def versions
    Version.where(project_id: @root.id)
  end
  
  def date_effective
    vArr = versions
    vArr = vArr.reject { |v| v.effective_date.nil? } 
    if vArr.blank?
      return super
    end 
    vArr.map { |v| v.effective_date }.max
  end
  
end