class Time
  def difference_in_months(time)
    if time.present? and self.present?
      (self.year * 12 + self.month) - (time.year * 12 + time.month)
    else
      0
    end
  end
  def differnce_in_days(date)
    if date.present? and self.present?
      self.to_date.mjd - date.mjd
    else
      0
    end
  end
end
