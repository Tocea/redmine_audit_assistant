class AuditController < ApplicationController
  unloadable

  def index
  	@project = Project.find(params[:project_id])
  	@audit = Audit.new
  end

  def create
  	attachments = params[:attachments]
  	puts "let's see what we've got here"
  	puts attachments[attachments.keys[0]]["token"]
  	token = attachments[attachments.keys[0]]["token"]
  	attach = Attachment.find_by_token(token)
  	puts attach	
  
  	project = Project.find(params[:project_id])
  	puts project
  
  	user = User.current
  	puts user
  
  	audit = Audit.new
  	audit.name = "Test audit"
  	audit.categories = [Category.new(:name => "Category", :description => "an awesome category")]
  	audit.toIssue(project)
  	
  end
end
