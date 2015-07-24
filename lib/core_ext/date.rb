class Date
  def difference_in_months(time)
      now = self
    if time.present? and now.present?
      (now.year * 12 + now.month) - (time.year * 12 + time.month)
    else
      0
    end
  end
end
