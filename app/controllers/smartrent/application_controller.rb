module Smartrent
  class ApplicationController < ActionController::Base
    # before_action :authenticate_user!
    # protect_from_forgery
    #layout :layout_by_resource
    def after_sign_in_path_for(resource)
      if resource.name == :resident
        request.env['omniauth.origin'] || stored_location_for(resource) || smartrent.root_path
      else
        request.env['omniauth.origin'] || stored_location_for(resource) || smartrent.admin_root_path
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
