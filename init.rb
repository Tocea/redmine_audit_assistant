Redmine::Plugin.register :redmine_audit_assistant do
  name 'Audit Assistant plugin'
  author 'Tocea'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://www.tocea.com'
  permission :import, { :import => [:index, :import] }, :public => true
  menu :project_menu, :import, { :controller => 'import', :action => 'index' }, :caption => 'Import', :after => :activity, :param => :project_id
end
