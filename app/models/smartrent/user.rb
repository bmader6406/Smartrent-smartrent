module Smartrent
  class User < ActiveRecord::Base
    # Include default devise modules. Others available are:
    # :confirmable, :lockable, :timeoutable and :omniauthable
    devise :database_authenticatable, :registerable,
           :recoverable, :rememberable, :trackable, :validatable, :lockable
           # :confirmable, :lockable, :token_authenticatable
  
    # Setup accessible (or protected) attributes for your model
    attr_accessible :email, :password, :password_confirmation, :remember_me, :name, :address
    # attr_accessible :title, :body

    def total_saved
      self.monthly_awards_amount + self.months_earned + self.total_earned + self.sign_up_bonus
    end
  end
end
