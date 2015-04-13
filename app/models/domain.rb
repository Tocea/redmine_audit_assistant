class Domain < ActiveRecord::Base
  
	belongs_to :category
	has_many :goals

	def toIssue(parent)

		issue = AuditHelper::AuditIssueFactory
			.createIssue(self.name, self.description, "audit - domaine", parent.project, parent)

		self.goals.each do |goal|
			goal.toIssue(issue)
		end

		issue
	end
end
