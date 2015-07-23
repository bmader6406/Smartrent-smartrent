module Smartrent
  class ResidentProperty < ActiveRecord::Base
    belongs_to :property
    belongs_to :resident
    validates_presence_of :property, :resident, :move_in_date
    after_create do
      if move_in_date.present? and status == Resident.SMARTRENT_STATUS_CURRENT and property.status == Property.STATUS_CURRENT and (Time.now.differnce_in_months(move_in_date)) >= 1 and (move_out_date.nil? or (move_out_date.differnce_in_months(Time.now.month)) == 1)
        (1..(Time.now.differnce_in_months(move_in_date))).each do |month|
          period_start = move_in_date.to_time.advance(:months => month).to_date
          Reward.create!(:property_id => property.id, :resident_id => resident.id, :amount => Setting.monthly_award, :type_ => Reward.TYPE_MONTHLY_AWARDS, :period_start => period_start, :period_end => 1.year.from_now)
        end
      end
    end
  end
end
