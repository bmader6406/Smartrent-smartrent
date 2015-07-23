require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::PropertiesController < Admin::AdminController
    before_filter :authenticate_admin!, :only => [:import, :import_page]
    before_action :set_property, :except => [:index]
    before_action do 
      @active = "properties"
    end
    # GET /properties
    # GET /properties.json
    def index
      authorize! :read, ::Property
      @properties = filter_properties#paginate(:page => params[:page], :per_page => 15)
      @search = params[:search]
  
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
    private
      def property_params
        params.require(:property).permit! if params[:property].present?
      end
      def set_property
        @property = Property.find(params[:id]) if params[:id]
        case action_name
          when "create"
            authorize! :cud, ::Property
          when "edit", "update", "destroy"
            authorize! :cud, @property
          when "read"
            authorize! :read, @property
          else
            authorize! :read, ::Property
        end
      end
      def filter_properties(per_page = 15)
        arr = []
        hash = {}
        
        ["_id","name", "city", "state", "zip", "website_url", "status"].each do |k|
          next if params[k].blank?
          if k == "_id"
            arr << "id = :id"
            hash[:id] = "#{params[k]}"
          else
            arr << "#{k} LIKE :#{k}"
            hash[k.to_sym] = "%#{params[k]}%"
          end
        end
        @properties = current_user.managed_properties.where(:is_smartrent => true).where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page).order("name asc")
      end
  end
end
