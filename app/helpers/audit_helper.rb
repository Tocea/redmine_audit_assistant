module AuditHelper

	class TrackerFactory

		def self.find_or_create(project, name)
			
			tracker = project.trackers.find_by_name(name)
			if !tracker
				tracker = project.trackers.create(:name => name)
			end
			tracker
		end

	end

	class PriorityFactory

		def self.find_or_create(name)

			priority = IssuePriority.find_by_name(name)
			if !priority
				priority = IssuePriority.new(:name => name)
				priority.save
			end
			priority
		end

	end

	class AuditIssueFactory
    
    # mapping of the properties of an issue
    # with the properties of a requirement
    @fields = {
      :subject => 'name',
      :description => 'description',
      :estimated_hours => 'charge'
    }

		def self.createIssue(requirement, project, parent)
		  
		  # check if the parameter 'project' is an
      # entire project or a project version
		  if project.instance_of? Version
		    version = project
		    project = version.project
		  end
		  
		  # get the tracker
			tracker_name = requirement.category
			tracker = AuditHelper::TrackerFactory.find_or_create(project, tracker_name)
			
			# get the priority
			priority = AuditHelper::PriorityFactory.find_or_create("Normal")

      # create a new issue
			issue = Issue.new(
				:author => User.current,
				:tracker => tracker, 
				:project => project,
				:assigned_to => User.current,
				:priority => priority			
			)
			
			# set the issue's properties from the requirement
			@fields.keys.each do |key|
        if (requirement[@fields[key]])
          issue[key] = requirement[@fields[key]]
        end
      end

      # check if it's a sub-issue
			if parent
			  
				issue.project = parent.project
				issue.parent = parent
				issue.fixed_version_id = parent.fixed_version_id		
				
				# get the root of the issue(s)
				root = issue
				while root.parent
				  root = root.parent
				end
				issue.root_id = root.id
				
      else
        
        # set the version id
        if version
          issue.fixed_version_id = version.id
        end
        
			end					

      # check if the issue can be validated
      if !issue.valid?
        puts issue.errors.full_messages
      end

      # save the issue
      issue.save
      
      # activate the autoclose custom field for this project/tracker
      autoclose_field = AutocloseIssuePatch::customField(project, tracker) 
      
      # set the value of the autoclose field    
      issue.custom_field_values = { autoclose_field.id => '1' }
      issue.save_custom_field_values
      issue.save
      
			issue
			
		end

	end

end
