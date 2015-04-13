class Audit < ActiveRecord::Base

	has_many :categories

	def toIssue(project)

		# tracker = AuditHelper::TrackerFactory.find_or_create(project, "audit")
		# priority = AuditHelper::PriorityFactory.find_or_create("Normal")

		#issue = Issue.new(
		#	:subject => self.name, 
		#	:description => self.description,
		#	:author => User.current, 
		#	:project => project, 
		#	:tracker => tracker, 
		#	:assigned_to => User.current,
		#	:priority => priority,
		#	:status => IssueStatus.find_by_name("Nouveau")
		#)

		#issue.valid?
		#puts issue.errors.full_messages
		#issue.save
		
		issue = AuditHelper::AuditIssueFactory
				.createIssue(self.name, "", "audit", project, nil)

		self.categories.each do |category|
			category.toIssue(issue)
		end

		issue
		
	end  

end
