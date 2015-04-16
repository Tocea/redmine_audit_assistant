require 'yaml'

class ImportController < ApplicationController
  unloadable

  helper :import
  include ImportHelper

  def index
    
    @project = Project.find(params[:project_id])
    @requirement = Requirement.new
    
    @versions = @project.shared_versions.open
    Rails.logger.info @versions.inspect
    
    @select_versions = [[l(:label_none), 0]]
    @versions.each do |v|
      @select_versions.push([v.name, v.id])
    end
    
    if params[:error_parsing_file]
      flash[:error] = l(:error_parsing_file)
    end  
    
  end

  def import
    
    # retrieve the project
    @project = Project.find(params[:project_id])
    
    # retrieve the version
    version_id = params[:version_id]
    if (version_id && version_id != '0')
      @version = Version.find(version_id)
    end
    
    # redirect to the index page if no attachment has been uploaded
    attachments = params[:attachments]
    if attachments
      token = attachments[attachments.keys[0]]["token"]  
    end
    if !token
      Rails.logger.info "No attachment found!"
      redirect_to :controller => 'import', :action => 'index', :project_id => @project.id
      return false
    end
    
    # retrieve the attachment   
    attach = Attachment.find_by_token(token)
    
    begin     
      # extract data from the attachment file
      data = import_from_yaml(attach.diskfile)
      requirements = data[:requirements]
    rescue StandardError=>e  
      # redirect to the index page if the file cannot be parsed
      Rails.logger.info "Error parsing file: #{e}"
      redirect_to :controller => 'import', :action => 'index', :project_id => @project.id, :error_parsing_file => true
      return false
    end
    
    # check if the version is specified in the file
    if !@version && data[:version]
      @version = data[:version]
      # look in the db if the version already exists     
      version_db = Version.where(project_id: @project.id, name: @version.name).first
      if version_db
        # use the version that already exists
        @version = version_db
      else
        # create a new version
        @version.project_id = @project.id
        if !@version.valid?
          Rails.logger.test @version.errors.full_messages
        end
        @version.save
      end
    end
    
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
