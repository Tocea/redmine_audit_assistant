class PeriodProgressReport
  
  attr_accessor :date_from, :date_to
  
  def initialize(date_from, date_to)
    
    @date_from = date_from
    @date_to = date_to
    
  end
  
  def to_end_of_week
    
    @date_to = Chronic.parse('next friday', :now => @date_from)
  
  end
  
  def self.week_periods(date_beggining_project)
    
    periods = Array.new
    
    date_from = Chronic.parse('monday', :context => :past)
    date_to = Chronic.parse('friday', :now => date_from)
    
    while date_to >= date_beggining_project do
      
      if date_from.kind_of?(Array)
        date_from = date_from[0]
      end
      
      periods.push(PeriodProgressReport.new(date_from, date_to))
      puts date_from.to_s+' '+date_to.to_s
      date_from = Chronic.parse('last monday', :now => date_from),
      
      date_to = Chronic.parse('last friday', :now => date_to)
      
    end

    periods   
  end
  
end