class Goal < ActiveRecord::Base
	
	belongs_to :domain  
	has_many :practices

	def toIssue(parent)

		issue = AuditHelper::AuditIssueFactory
			.createIssue(self.name, self.description, "audit - objectif", parent.project, parent)

		self.practices.each do |practice|
			practice.toIssue(issue)
		end

		issue
	end
end
