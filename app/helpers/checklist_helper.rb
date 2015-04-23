module ChecklistHelper
 
 # verify if the Checklist plugin is installed in Redmine
 def available?   
   checklist_path = File.dirname(__FILE__) + '/../../../redmine_checklists/app/models/checklist.rb'
   return false unless File.exist? checklist_path
   load checklist_path
   return false unless checklist_from_plugin
   true
 end
 
 # get the Checklist plugin's model class
 def checklist_from_plugin
   Object.const_get('Checklist')
 end
 
 # create a checklist in an issue from the requirement's data
 def create_issue_checklist(requirement, issue)
   
   return false unless requirement.checklist && available? 
   
   requirement.checklist.each do |item|
     
     checklist = checklist_from_plugin.new(
        :issue => issue, 
        :subject => item
     )
     
     checklist.save
     
   end
   
 end
 
end