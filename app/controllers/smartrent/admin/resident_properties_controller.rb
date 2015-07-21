require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::ResidentPropertiesController < Admin::AdminController
    before_filter :authenticate_admin!, :only => [:import, :import_page]
    before_action :set_property
    before_action do 
      @active = "residents"
    end
    def show
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @resident_property }
      end
    end
  
    def new
      @resident_property = ResidentProperty.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @resident_property }
      end
    end
  
    def edit
    end
  
    def create
      @resident_property = ResidentProperty.new(property_params)
  
      respond_to do |format|
        if @resident_property.save
          format.html { redirect_to admin_property_path(@resident_property), notice: 'Property was successfully created.' }
          format.json { render json: @resident_property, status: :created, location: @resident_property }
        else
          format.html { render action: "new" }
          format.json { render json: @resident_property.errors, status: :unprocessable_entity }
        end
      end
    end
  
    def update
      respond_to do |format|
        if @resident_property.update_attributes(property_params)
          format.html { redirect_to admin_resident_property_path(@resident_property), notice: 'Property was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @resident_property.errors, status: :unprocessable_entity }
        end
      end
    end
  
    def destroy
      resident = @resident_property.resident
      @resident_property.destroy
  
      respond_to do |format|
        format.html { redirect_to properties_admin_resident_path(resident) }
        format.json { head :no_content }
      end
    end
    private
      def property_params
        params.require(:resident_property).permit!
      end
      def set_property
        @resident_property = ResidentProperty.find(params[:id]) if params[:id]
        case action_name
          when "create"
            authorize! :cud, ::Resident
          when "edit", "update", "destroy"
            authorize! :cud, @resident_property.resident
          when "read"
            authorize! :read, @resident_property.resident
          else
            authorize! :read, ::Resident
        end
      end
  end
end
