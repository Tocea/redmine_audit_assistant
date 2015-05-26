
class AdminMenuHooks < Redmine::Hook::ViewListener
  
  def view_layouts_base_html_head(context = {})
    stylesheet_link_tag('audit_assistant.css', :plugin => 'redmine_audit_assistant')
  end
  
end