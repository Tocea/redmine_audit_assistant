require 'yaml'

class ImportController < ApplicationController
  unloadable

  def index
    @project = Project.find(params[:project_id])
    @requirement = Requirement.new
    
    @versions = @project.shared_versions.open
    puts @versions.inspect
    
    @select_versions = [[l(:label_none), 0]]
    @versions.each do |v|
      @select_versions.push([v.name, v.id])
    end

  end

  def import
    
    # retrieve the project
    @project = Project.find(params[:project_id])
    puts @project
    
    # retrieve the version
    version_id = params[:version_id]
    puts version_id
    if (version_id && version_id != '0')
      @version = Version.find(version_id)
    end
    puts @version.inspect
    
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
      if @version
        r.toIssue(@version)
      else
        r.toIssue(@project)
      end    
    end
    
    if requirements.count == 1
      # redirect to the page that display the root issue
      redirect_to :controller => 'issues', :action => 'show', :id => requirements[0].issue.id
    else
      # redirect to the page that display the issues
      redirect_to :controller => 'issues', :action => 'index', :project_id => @project.id
    end
    
  end
end
