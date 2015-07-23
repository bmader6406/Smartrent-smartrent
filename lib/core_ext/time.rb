class Time
  def differnce_in_months(time)
    if time.present? and self.present?
      (self.year * 12 + self.month) - (time.year * 12 + month)
    else
      0
    end
  end
end
