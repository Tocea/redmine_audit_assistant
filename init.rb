Redmine::Plugin.register :redmine_audit_assistant do
  name 'Audit Assistant plugin'
  author 'Tocea'
  description 'Redmine plugin to assist consultants to perform (code) audits.'
  version '1.0'
  url 'https://github.com/Tocea/redmine_audit_assistant'
  author_url 'http://www.tocea.com'
  permission :import, { :import => [:index, :import] }, :public => true
  permission :progress_report, { :progress_report => [:index, :generate] }, :public => true
  menu :project_menu, :import, { :controller => 'import', :action => 'index' }, :caption => 'Import', :after => :activity, :param => :project_id
  menu :project_menu, :progress_report, { :controller => 'progress_report', :action => 'index' }, :caption => :progress_report_title, :after => :activity, :param => :project_id
end


require 'autoclose_issue_patch'
require 'workflow_buttons_hook'
