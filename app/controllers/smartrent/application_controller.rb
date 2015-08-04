module Smartrent
  class ApplicationController < ::ApplicationController
    # before_action :authenticate_user!
    # protect_from_forgery
    layout :layout_by_resource
    
    def after_sign_in_path_for(resource)
      if resource_name == :resident
        request.env['omniauth.origin'] || stored_location_for(resource) || smartrent.root_path
      else
        request.env['omniauth.origin'] || stored_location_for(resource) || smartrent.admin_root_path
      end
    end
    
    def require_no_user
      if current_user
        store_location
        # click on invite link, auto redirect to the invite org if logged in
        redirect_url = accept_invite_and_redirect(current_user, params[:token]) || back_or_default_url( root_url(:protocol => "http") + "/admin" )
        redirect_to redirect_url
        return false
      end
    end
    
    def layout_by_resource
      if devise_controller? && resource_name == :admin_user
        "smartrent/admin"
      else
        "smartrent/application"
      end
    end
    
    def after_sign_out_path_for(resource)
      if resource == :resident
        smartrent.root_path
      else
        smartrent.admin_root_path
      end
    end

  end
end
