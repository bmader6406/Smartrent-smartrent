module Smartrent
  class ResidentHome < ActiveRecord::Base
    belongs_to :resident
    belongs_to :home
    validates_presence_of :resident, :home
  end
end
