module Smartrent
  class ResidentProperty < ActiveRecord::Base
    belongs_to :property
    belongs_to :resident
    validates_presence_of :property, :resident, :move_in_date
    validates_uniqueness_of :move_in_date, :scope => [:resident_id, :property_id]
    after_create do
      if move_in_date.present? and property.status == Property.STATUS_CURRENT and (Time.now.difference_in_months(move_in_date)) >= 1 and (move_out_date.nil? or (move_out_date.difference_in_months(Time.now.month)) == 1)
        (1..(Time.now.difference_in_months(move_in_date))).each do |month|
          period_start = move_in_date.to_time.advance(:months => month).to_date
          Reward.create!(:property_id => property.id, :resident_id => resident.id, :amount => Setting.monthly_award, :type_ => Reward.TYPE_MONTHLY_AWARDS, :period_start => period_start, :period_end => 1.year.from_now)
        end
      end
    end
    def self.STATUS_CURRENT
      "Current"
    end
    def self.STATUS_PAST
      "Past"
    end
    def self.STATUS_NOTICE
      "Notice"
    end
    def self.statuses
      {self.STATUS_CURRENT => "Current", self.STATUS_PAST => "Past", self.STATUS_NOTICE => "Notice"}
    end
  end
end
