require 'yaml'

class ImportController < ApplicationController
  unloadable

  before_filter :find_project, :authorize
  before_filter :find_version, :only => :import
  before_filter :find_attachment, :only => :import

  helper :import
  include ImportHelper

  def index
    
    @requirement = Requirement.new
    
    @versions = @project.shared_versions.open
    Rails.logger.info @versions.inspect
    
    @select_versions = [[l(:label_none), 0]]
    @versions.each do |v|
      @select_versions.push([v.name, v.id])
    end
    
  end

  def import
    
    # redirect to the index page if no attachment has been uploaded
    if !@attachment
      Rails.logger.info "No attachment found!"
      redirect_to :controller => 'import', :action => 'index', :project_id => @project.id
      return false
    end
    
    begin     
      # extract data from the attachment file
      data = import_from_yaml(@attachment.diskfile)
      requirements = data[:requirements]
    rescue StandardError=>e  
      # redirect to the index page if the file cannot be parsed
      Rails.logger.info "Error parsing file: #{e}"
      flash[:error] = l(:error_parsing_file) + '<br/>' + e.message
      redirect_to :controller => 'import', :action => 'index', :project_id => @project.id, :flash => flash
      return false
    end
    
    # check if the version is specified in the file
    if !@version && data[:version]
      @version = get_or_create_version(data[:version], @project)
    end
    
    # create issues from the requirements
    requirements.each do |r|
      r.toIssue(@version ? @version : @project)  
    end
    
    # lock the version
    lock_version(@version) unless @version.nil?
    
    if requirements.count == 1
      # redirect to the page that display the root issue
      redirect_to :controller => 'issues', :action => 'show', :id => requirements[0].issue.id
    else
      # redirect to the page that display the issues
      redirect_to :controller => 'issues', :action => 'index', :project_id => @project.id
    end
    
  end
  
  private # -----------------------------------------------------------------------------------
  
  # retrieve the project
  def find_project
    @project = Project.find(params[:project_id])
  end
  
  # retrieve the version
  def find_version
    version_id = params[:version_id]
    if (version_id && version_id != '0')
      @version = Version.find(version_id)
    end
  end
  
  # retrieve the uploaded file
  def find_attachment
    
    # redirect to the index page if no attachment has been uploaded
    attachments = params[:attachments]
    token = attachments[attachments.keys[0]]["token"] if attachments
    
    if token
      # retrieve the attachment
      @attachment = Attachment.find_by_token(token)
    end

  end
  
  # create a new version of a project
  # or retrieve it from the db if it already exists
  def get_or_create_version(version, project)  
    # look in the db if the version already exists     
    version_db = Version.where(project_id: project.id, name: version.name).first
    if version_db     
      # check if the effective date have changed
      if version.effective_date && version.effective_date != version_db.effective_date
        # update the effective date
        version_db.effective_date = version.effective_date
        version_db.save
      end
      # use the version that already exists
      version = version_db
    else
      # create a new version
      version.project_id = project.id
      version.save
    end
    version
  end
  
  
  # lock a version
  def lock_version(version)
    
    version.status = 'locked'
    version.save
    
  end
  
end
