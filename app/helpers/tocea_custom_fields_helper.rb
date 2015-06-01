module ToceaCustomFieldsHelper
  
  def code_project(project)
    
    field = ProjectCustomField.find_by_name('Code Projet')
    
    project.custom_value_for(field.id).to_s unless field.nil?
    
  end
  
  def code_version(version)
    
    field = VersionCustomField.find_by_name('Code Projet')
    
    version.custom_value_for(field.id).to_s unless field.nil?
    
  end
  
  def version_initial_workload(version)
    
    field = VersionCustomField.find_by_name('Charge initiale')
    
    field.nil? ? 0.00 : version.custom_value_for(field.id).to_s.to_f
    
  end
  
end