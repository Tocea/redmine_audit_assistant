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
				
				# get the root of the issue(s)
				root = issue
				while root.parent
				  root = root.parent
				end
				issue.root_id = root.id

			end					

      # check if the issue can be validated
      if !issue.valid?
        puts issue.errors.full_messages
      end
      
      # save the issue
      issue.save
      
			issue
			
		end

	end

end
