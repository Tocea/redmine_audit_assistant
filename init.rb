Redmine::Plugin.register :redmine_audit_assistant do
  name 'Audit Assistant plugin'
  author 'Tocea'
  description 'Redmine plugin to assist consultants to perform (code) audits.'
  version '1.0'
  url 'https://github.com/Tocea/redmine_audit_assistant'
  author_url 'http://www.tocea.com'
  
  menu :project_menu, :import, { :controller => 'import', :action => 'index' }, :caption => 'Import', :after => :activity, :param => :project_id
  menu :project_menu, :progress_report, { :controller => 'progress_report', :action => 'index' }, :caption => :progress_report_title, :after => :activity, :param => :project_id
  menu :admin_menu, :issues_custom_actions, { :controller => 'issues_custom_actions', :action => 'settings', :caption => :issue_custom_actions_settings_title }
  
  project_module :progress_report do
    permission :progress_report, { :progress_report => [:index, :generate, :empty] }
  end
  
  project_module :import do
    permission :import, { :import => [:index, :import] }
  end
  
end


require 'autoclose_issue_patch'
require 'workflow_buttons_hook'
require 'admin_menu_hooks'
