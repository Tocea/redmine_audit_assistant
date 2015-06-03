class TimeFormatter
  
  def initialize(nb_hours_per_day)
    @nb_hours_per_day = nb_hours_per_day ? nb_hours_per_day : 8.00
  end

  def format_hours(hours, to='h')
    hours = 0 if hours.nil?
    if to == 'd'
       hours = hours / @nb_hours_per_day
       hours = hours >= 0 ? hours.ceil : hours.floor
    end
    hours 
  end
  
  def format_days(days, to='h')
    hours = days ? days : 0
    if to == 'h'
       hours = hours * @nb_hours_per_day
       hours = hours >= 0 ? hours.ceil : hours.floor
    end
    hours
  end
  
end