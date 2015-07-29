module Smartrent
  class ResidentHome < ActiveRecord::Base
    belongs_to :resident
    belongs_to :home
    
    validates :resident, :home, :presence => true
  end
end
