class ProgressReportExport
  
  def initialize(report)
    
    @report = report
    
  end
  
  def export(html_content)
    
    @html = html_content
    
    filename = report_filename
    
    # create the temporary file
    File.open(filename, 'w:UTF-8') do |f|
      f.puts @html.encode('utf-8')
    end
    
    # destroy the previous reports on the same period
    destroy_attachments_same_period(filename)
    
    # save the file in the project's attachments
    save_attachment(filename)
    
    #destroy the temporary file
    File.delete(filename)
    
  end
  
  def last_report
    
    attachments = find_attachments_same_period(report_filename)
    
    attachments.blank? ? nil : attachments[0]
    
  end
  
  private # -------------------------------------------------------------------------------------------------------
  
  # get the name of the generated file that contains the report
  def report_filename(version=nil)
    
    filename = 'Report'
    filename += ' - '+@report.version.name if @report.version
    filename += '.html' 
    
    filename
  end
  
  # save the file as a project's attachment
  def save_attachment(filename)
    
    attachment = Attachment.new(:file => File.open(filename, 'r:UTF-8'))
    attachment.author = User.current
    attachment.filename = filename
    attachment.container = @report.project
    attachment.save
    
  end
  
  # destroy all attachments of the same report on the same period
  def destroy_attachments_same_period(filename)
    
    attachments = find_attachments_same_period(filename)
    
    if !attachments.blank?
      attachments.each { |attachment| attachment.destroy }
    end
    
  end
  
  def find_attachments_same_period(filename)
    
    Attachment.where("container_type = 'Project' AND container_id = :project_id AND filename = :filename AND created_on >= :date_from AND created_on <= :date_to", {
      project_id: @report.project.id,
      filename: filename,
      date_from: @report.period.date_from.to_date,
      date_to: @report.period.date_to.to_date + 1.day
    })
    
  end
  
end