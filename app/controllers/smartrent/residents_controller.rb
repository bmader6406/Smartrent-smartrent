require_dependency "smartrent/application_controller"

module Smartrent
  class ResidentsController < ApplicationController
    before_action :set_resident

    def profile
      authenticate_resident!
      respond_to do |format|
        format.html {}
      end
    end
    
    def update_password
      authenticate_resident!
      @resident.update_password(resident_params)
      if @resident.errors.any?
        render "change_password"
      else
        sign_in(@resident, :bypass => true)
        redirect_to change_password_residents_path, :notice => "Your password has been updated successfully"
      end
    end
    
    def change_password
      authenticate_resident!
    end
    
    def statement
      authenticate_resident!
      respond_to do |format|
        format.html {}
      end
    end
    
    private
    
      def resident_params
        params.require(:resident).permit! if params[:resident].present?
      end
      
      def set_resident
        @resident = current_resident if current_resident
      end
      
  end
end
