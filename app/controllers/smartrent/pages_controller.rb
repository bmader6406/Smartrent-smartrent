require_dependency "smartrent/application_controller"

module Smartrent
  class PagesController < ApplicationController
    def home
      respond_to do |format|
        format.html
      end
    end
    def faq
      @current_page = "faq"
      respond_to do |format|
        format.html
      end
    end
    def new_home
      respond_to do |format|
        format.html
      end
    end
    def program_rules
      @current_page = "program_rules"
      respond_to do |format|
        format.html
      end
    end
    def official_rules
      respond_to do |format|
        format.html
      end
    end
    def privacy_policy
      respond_to do |format|
        format.html
      end
    end
    def website_disclaimer
      respond_to do |format|
        format.html
      end
    end

    def ny_avenue
      respond_to do |format|
        format.html
      end
    end
    def terms_of_use
      respond_to do |format|
        format.html
      end
    end

  end
end
