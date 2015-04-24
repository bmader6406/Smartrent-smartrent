require_dependency "smartrent/application_controller"

module Smartrent
  class ContactsController < ApplicationController
    # GET /contacts/new
    def new
      @contact = Contact.new
  
      respond_to do |format|
        format.html # new.html.erb
      end
    end
  
    # POST /contacts
    # POST /contacts.json
    def create
      @contact = Contact.new(params[:contact])
  
      respond_to do |format|
        if @contact.save
          format.html { redirect_to new_contact_path, notice: 'Thank You for contacting us we we\'ll be with you shortly.'}
        else
          format.html { render action: "new" }
        end
      end
    end
  end
end
