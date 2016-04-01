require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::TestAccountsController < Admin::AdminController

    before_action :require_admin
    before_action :set_test_account, except: [:index, :new, :create]

    def index
      @test_account = TestAccount.new
      @test_accounts = TestAccount.includes(:resident).all
    end

    def create
      @error = nil
      
      test_account_params[:origin_email].strip!
      test_account_params[:new_email].strip!
      
      sr = Smartrent::Resident.find_by_email( test_account_params[:origin_email] )
      
      if !sr
        @error = "#{test_account_params[:origin_email]} does not exist, please choose another email"
        
      elsif !sr.confirmed_at.blank?
        @error = "#{test_account_params[:origin_email]} has been already activated, please choose another email"
        
      else
        
        new_email_sr = Smartrent::Resident.find_by_email( test_account_params[:new_email] )
        
        if new_email_sr
          @error = "#{test_account_params[:new_email]} has been taken, please choose another email"
          
        else
          @test_account = TestAccount.new(test_account_params)
          @test_account.resident_id = sr.id
          @test_account.save
        end
      end
    end

    def destroy
      @test_account.update_attribute(:deleted_at, Time.now)
    end
    
    def reset_password
      @test_account.resident.send_reset_password_instructions
      @test_account.resident.update_attribute(:confirmed_at, Time.now) if @test_account.resident.confirmed_at.blank?
      
      render :json => {:success => true}
    end
    
    def reset_activation_date
      @test_account.resident.update_attribute(:confirmed_at, nil)
      render :json => {:success => true}
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_test_account
        @test_account = TestAccount.find(params[:id])
      end

      # Only allow a trusted parameter "white list" through.
      def test_account_params
        params.require(:test_account).permit(:resident_id, :origin_email, :new_email, :deleted_at)
      end
  end
end
