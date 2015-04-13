class Practice < ActiveRecord::Base
  
	belongs_to :goal

	def toIssue(parent)

		issue = AuditHelper::AuditIssueFactory
			.createIssue(self.name, self.description, "audit - pratique", parent.project, parent)

		issue
	end

end
