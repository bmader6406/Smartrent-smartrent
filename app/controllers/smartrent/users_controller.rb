require_dependency "smartrent/application_controller"

module Smartrent
  class UsersController < ApplicationController
    before_filter :authenticate_user!
    def profile
      respond_to do |format|
        format.html {}
      end
    end
  end
end
