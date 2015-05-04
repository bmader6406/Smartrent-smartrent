require_dependency "smartrent/application_controller"

module Smartrent
  class ResidentsController < ApplicationController
    before_filter :authenticate_resident!
    def profile
      @resident = current_resident
      respond_to do |format|
        format.html {}
      end
    end
    def statement
      @resident = current_resident
      respond_to do |format|
        format.html {}
      end
    end
  end
end
