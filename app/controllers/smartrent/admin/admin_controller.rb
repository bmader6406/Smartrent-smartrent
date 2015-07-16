require_dependency "smartrent/application_controller"
module Smartrent
  class Admin::AdminController < ApplicationController
    before_filter :require_user
    layout "smartrent/admin"
    rescue_from CanCan::AccessDenied do |exception|
      msg = "Access denied on #{exception.action} #{exception.subject.inspect} - #{current_user.id}"
      ppp msg
      
      respond_to do |format|
        format.html {
          flash[:error] = "You are not authorized to access that page"
          redirect_to admin_root_url, :alert => "You are not authorized to access that page"
        }
        format.json {
          render :json => {:error => "401 Unauthorized"}, :status => 401
        }
      end
    end
  end
end
