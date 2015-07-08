require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::PropertiesController < Admin::AdminController
    before_action :set_property
    # GET /properties
    # GET /properties.json
    def index
      @active = "properties"
      @properties = Property.paginate(:page => params[:page], :per_page => 15)
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @properties }
      end
    end
  
    # GET /properties/1
    # GET /properties/1.json
    def show
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @property }
      end
    end
  
    # GET /properties/new
    # GET /properties/new.json
    def new
      @property = Property.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @property }
      end
    end
  
    # GET /properties/1/edit
    def edit
    end
  
    # POST /properties
    # POST /properties.json
    def create
      @property = Property.new(property_params)
  
      respond_to do |format|
        if @property.save
          format.html { redirect_to admin_property_path(@property), notice: 'Property was successfully created.' }
          format.json { render json: @property, status: :created, location: @property }
        else
          format.html { render action: "new" }
          format.json { render json: @property.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /properties/1
    # PUT /properties/1.json
    def update
      @property = Property.find(params[:id])
  
      respond_to do |format|
        if @property.update_attributes(property_params)
          format.html { redirect_to admin_property_path(@property), notice: 'Property was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @property.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /properties/1
    # DELETE /properties/1.json
    def destroy
      @property = Property.find(params[:id])
      @property.destroy
  
      respond_to do |format|
        format.html { redirect_to admin_properties_url }
        format.json { head :no_content }
      end
    end
    def import_page
      @active = "properties"
      render :import
    end
    def import
      Property.import(params[:file])
      redirect_to admin_properties_path, notice: "Properties have been imported"
    end
    def set_property
      @property = Property.find(params[:id]) if params[:id]
    end
    
    private
    
      def property_params
        params.require(:property).permit!
      end
  end
end
