class Category < ActiveRecord::Base
	
	belongs_to :audit
	has_many :domains

	def toIssue(parent)

		issue = AuditHelper::AuditIssueFactory
				.createIssue(self.name, self.description, "audit - catégorie", parent.project,	parent)

		# tracker = AuditHelper::TrackerFactory.find_or_create(parent.project, "audit - catégorie")
		# priority = AuditHelper::PriorityFactory.find_or_create("Normal")
		#status = IssueStatus.find_by_name("Nouveau")

		#issue = Issue.new(
		#	:subject => self.name, 
		#	:description => self.description,
		#	:author => User.current, 
		#	:project => parent.project,
		#	:parent => parent,
		#	:tracker => tracker, 
		#	:assigned_to => User.current,
		#	:priority => priority,
		#	:status => status
		#)

		#issue.valid?
		#puts issue.errors.full_messages
		#issue.save

		self.domains.each do |domain|
			domain.toIssue(issue)
		end

		issue

	end

end
