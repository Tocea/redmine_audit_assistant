class ProgressReportBuilder
  
  def initialize(root)
    @root = root
  end
  
  def from(date_from)
    @date_from = date_from
    self
  end
  
  def to(date_to)
    @date_to = date_to
    self
  end
  
  def with(params)
    @params = params
    self
  end
  
  def build
    
    return nil if @root.nil?
      
    period = PeriodProgressReport.new(@date_from, @date_to)
    @params = {} if @params.nil?
    
    @params[:occupation_persons] = format_integer_map(@params[:occupation_persons])
    @params[:days_off] = format_integer_map(@params[:days_off])
    
    if @root.kind_of?(Project)
      report = ProjectProgressReport.new(@root, period, @params)
    else
      report = ProjectVersionProgressReport.new(@root, period, @params)
    end
    
    report
  end
  
  private # ------------------------------------------------------------------------------------
  
  # format the hashmap that represent the percentage of occupation per person
  # it should not contains string and each value should be strictly greater than 0
  def format_integer_map(param)
    res = Hash.new
    if param
      res = Hash[param.keys.map(&:to_i).zip(param.values.map(&:to_i))]
    end
    res.select { |k,v| v.is_a?(Numeric) && v > 0 }
  end
  
end