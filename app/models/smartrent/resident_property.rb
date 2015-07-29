# this table is maintained by resque
# when the resident change on CRM, resque will update the smartrent residents appropriately

module Smartrent
  class ResidentProperty < ActiveRecord::Base
    belongs_to :property
    belongs_to :resident
    
    validates :property, :resident, :move_in_date, :presence => true
    #validates :move_in_date, :uniqueness => true, :scope => [:resident_id, :property_id]
    
    after_create :create_reward
    
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
    
    private
    
      def create_reward
        if move_in_date.present? && property.status == Property.STATUS_CURRENT && (Time.now.difference_in_months(move_in_date)) >= 1 && 
            (move_out_date.nil? || (move_out_date.difference_in_months(Time.now.month)) == 1)
            
          (1..(Time.now.difference_in_months(move_in_date))).each do |month|
            period_start = move_in_date.to_time.advance(:months => month).to_date
            Reward.create!({
              :property_id => property.id, 
              :resident_id => resident.id, 
              :amount => Setting.monthly_award, 
              :type_ => Reward.TYPE_MONTHLY_AWARDS, 
              :period_start => period_start, 
              :period_end => 1.year.from_now
            })
          end
        end
      end
  end
end
