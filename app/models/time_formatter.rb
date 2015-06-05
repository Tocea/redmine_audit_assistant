class TimeFormatter
  
  def initialize(nb_hours_per_day)
    @nb_hours_per_day = nb_hours_per_day ? nb_hours_per_day : 8.00
  end

  def format_hours(hours, to='h')
    days = hours ? hours : 0
    if to == 'd'
       days = days / @nb_hours_per_day
       days = days >= 0 ? days.ceil : days.floor
    end
    days 
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