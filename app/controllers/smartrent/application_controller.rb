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
    protected

  end
end
