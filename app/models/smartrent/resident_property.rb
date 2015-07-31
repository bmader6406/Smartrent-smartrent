# this table is maintained by resque
# when the resident change on CRM, resque will update the smartrent residents appropriately

module Smartrent
  class ResidentProperty < ActiveRecord::Base
    belongs_to :property
    belongs_to :resident
    
    validates :property, :resident, :move_in_date, :presence => true
    #validates :move_in_date, :uniqueness => {:scope => [:resident_id, :property_id]}
    
    after_create :create_rewards
    
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
    
      def create_rewards
        move_in_diff = Time.now.difference_in_months(move_in_date) rescue 0
        move_out_diff = move_out_date.difference_in_months(Time.now.month) rescue 1
        
        if property.status == Property.STATUS_CURRENT && move_in_diff >= 1 &&  move_out_diff == 1
          (1..move_in_diff).each do |month|
            period_start = move_in_date.to_time.advance(:months => month).to_date
            Reward.create!({
              :property_id => property.id, 
              :resident_id => resident.id, 
              :amount => Setting.monthly_award, 
              :type_ => Reward.TYPE_MONTHLY_AWARDS, 
              :period_start => period_start.beginning_of_month, 
              :period_end => period_start.end_of_month
            })
          end
        end
      end
  end
end
