module Smartrent
  class ApplicationController < ActionController::Base
    # before_action :authenticate_user!
    # protect_from_forgery
    def after_sign_in_path_for(resource)
      request.env['omniauth.origin'] || stored_location_for(resource) || smartrent.root_path
    end
    def after_sign_out_path_for(resource)
      smartrent.root_path
    end
  end
end
