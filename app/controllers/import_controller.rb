require 'yaml'

class ImportController < ApplicationController
  unloadable

  def index
    @project = Project.find(params[:project_id])
    @requirement = Requirement.new
  end

  def import
    
    # retrieve the project
    @project = Project.find(params[:project_id])
    puts @project
    
    # retrieve the attachment
    attachments = params[:attachments]
    puts attachments[attachments.keys[0]]["token"]
    token = attachments[attachments.keys[0]]["token"]
    attach = Attachment.find_by_token(token)
    puts attach
    
    # convert the attachment to Requirement objects
    requirements = ImportHelper::import_from_yaml(attach.diskfile)
    
    # create issues from the requirements
    requirements.each do |r|
      r.toIssue(@project)
    end
    
    if requirements.count == 1
      # redirect to the page that display the root issue
      redirect_to :controller => 'issues', :action => 'index', :id => requirements[0].issue.id
    else
      # redirect to the page that display the issues
      redirect_to :controller => 'issues', :action => 'index', :project_id => @project.id
    end
    
  end
end
