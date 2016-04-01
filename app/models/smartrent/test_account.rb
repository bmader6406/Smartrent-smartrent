module Smartrent
  class TestAccount < ActiveRecord::Base
    
    validates :resident_id, :origin_email, :new_email, :presence => true
    validates :resident_id, :uniqueness => {:scope => :deleted_at}
    
    validates :origin_email, :new_email, :format => { :with => /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/i }
    
    has_one :resident, :primary_key => :resident_id, :foreign_key => :id
    
    default_scope { where(:deleted_at => nil).order('origin_email asc') }
    
    before_create :change_smartrent_resident_email
    after_save :revert_smartrent_resident_email_if_delete
    
    
    def self.human_attribute_name(name, options = {})
      {"origin_email" => "Real Resident Email", "new_email" => "Test Email" }[name.to_s] || name.to_s.humanize
    end
    
    private
    
      def change_smartrent_resident_email
        resident.update_attribute(:email, new_email)
        
        if !resident.errors.empty?
          errors.add(:origin_email, "is not unique")
        end
      end
      
      def revert_smartrent_resident_email_if_delete
        if deleted_at_changed? && deleted_at_was.nil?
          resident.update_attributes(:email => origin_email, :confirmed_at => nil)
          
          if resident.errors.empty?
            return true
          else
            errors.add(:base, resident.errors.full_messages)
            return false
          end
        end
      end
      
  end
end
