class IssuesCustomActionsController < ApplicationController
  unloadable

  def start
    
    @issue = Issue.find(params[:issue_id]) 
    
    if @issue.start_date.nil?
      @issue.start_date = Time.now
      @issue.save
    end
    
    redirect_to :controller => 'issues', :action => 'show', :id => @issue.id
    
  end
  
end
