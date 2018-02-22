# frozen_string_literal: true
class CronGenerator
  attr_reader :frequency, :at_hour, :at_minutes

  def initialize(frequency, at_hour = nil, at_minutes = nil, offset = nil)
    @frequency = frequency
    @at_hour = at_hour.present? ? at_hour : '0'
    @at_minutes = at_minutes.present? ? at_minutes : '0'
    @offset = offset.present? ? offset.to_i : 0
  end

  def offset
    case frequency
    when 'weekly' then @offset > 6 ? 6 : @offset
    when 'fortnightly' then @offset > 13 ? 13 : @offset
    when 'monthly' then @offset > 27 ? 27 : @offset
    else @offset
    end
  end

  def month_day
    case frequency
    when 'fortnightly' then "#{1 + offset},#{15 + offset}"
    when 'monthly' then (1 + offset).to_s
    else '*'
    end
  end

  def week_day
    if frequency == 'weekly'
      offset.to_s
    else
      '*'
    end
  end

  def month
    '*'
  end

  def output
    "#{at_minutes} #{at_hour} #{month_day} #{month} #{week_day}"
  end
end
