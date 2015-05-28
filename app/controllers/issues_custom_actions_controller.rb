class IssuesCustomActionsController < ApplicationController
  unloadable
  
  before_filter :authorize_global
  
  def settings
    
    @status_action = IssueStatusActions.new
    
    @statuses = IssueStatus.order(:position).map { |status| [status.name, status.id] }
    
    @status_actions = IssueStatusActions.all.reject { |action| action.status_from.nil? || action.status_to.nil? }
    
    if params[:error]
      flash[:error] = l(:issue_custom_actions_settings_error)
    end
    
  end
  
  def insert
    
    begin     
      status_from = IssueStatus.find(params[:status_from])
      status_to = IssueStatus.find(params[:status_to]) 
    rescue StandardError => e
      show_error_msg
      return
    end
    
    @status_action = IssueStatusActions.new
    @status_action.lib = params[:action_lib]
    @status_action.status_from = status_from
    @status_action.status_to = status_to
    
    if @status_action.valid?
      
      @status_action.save    
       
      redirect_to :controller => 'issues_custom_actions', :action => 'settings'
      
    else
      
      show_error_msg
      
    end

  end
  
  def delete
    
    @status_action = IssueStatusActions.find(params[:action_id])
    @status_action.destroy
    
    redirect_to :controller => 'issues_custom_actions', :action => 'settings'
    
  end
  
  def run
    
    @action = IssueStatusActions.find(params[:action_id])
    @issue = Issue.find(params[:issue_id])
    
    @action.run(@issue)
    
    redirect_to :controller => 'issues', :action => 'show', :id => @issue.id
    
  end
  
  private # ------------------------------------------------------------------------------
  
  def show_error_msg
    
    redirect_to :controller => 'issues_custom_actions', :action => 'settings', :error => 1
    
  end
  
end
