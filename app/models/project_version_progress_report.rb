class ProjectVersionProgressReport < ProgressReport
  
  # returns the version's issues
  # in their state during the report's period
  def issues
    if @issues.nil?
      # the function that restore issues to their previous states
      # is very costly, so it must be called only once per report
      @issues = Issue.where(fixed_version_id: @root.id)
      restore_issues_states(@issues, @date_from, @date_to)
    end
    @issues
  end
  
  def date_effective
    @root.effective_date
  end
  
  def charge_initial(format='h')
    
    total = version_initial_workload(@root)
    
    @time_formatter.format_days(total.to_i, format)
    
  end
  
end