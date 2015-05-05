require_dependency "smartrent/application_controller"

module Smartrent
  class ResidentsController < ApplicationController
    before_filter :authenticate_resident!
    before_filter :set_resident

    def profile
      respond_to do |format|
        format.html {}
      end
    end
    def update_password
      @resident.update_password(params[:resident])
      if @resident.errors.any?
        render "change_password"
      else
        sign_in(@resident, :bypass => true)
        redirect_to change_password_residents_path, :notice => "Your password has been updated successfully"
      end
    end
    def change_password
    end
    def statement
      respond_to do |format|
        format.html {}
      end
    end
    def set_resident
      @resident = current_resident || Resident.find(params[:id])
    end
  end
end
