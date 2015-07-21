module Smartrent
  class ResidentProperty < ActiveRecord::Base
    belongs_to :property
    belongs_to :resident
    validates_presence_of :property, :resident
    after_create do
      if move_in_date.present? and status == Resident.SMARTRENT_STATUS_CURRENT and property.status == Property.STATUS_CURRENT and (Time.now.month - move_in_date.month) >= 1 and (move_out_date.nil? or (move_out_date.month - Time.now.month) == 1)
        Reward.create!(:property_id => property.id, :resident_id => resident.id, :amount => Setting.monthly_award, :type_ => Reward.TYPE_MONTHLY_AWARDS, :period_start => Time.now, :period_end => 1.year.from_now)
      end
    end
  end
end
