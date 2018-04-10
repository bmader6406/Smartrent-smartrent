require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::PropertiesController < Admin::AdminController
    before_action :set_property, :except => [:index]

    # GET /properties
    # GET /properties.json
    def index
      authorize! :read, ::Property
      @properties = filter_properties
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @properties }
        format.csv { render text: Smartrent::Property.to_csv }
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

    def export
      send_data(Smartrent::Property.to_csv, 
        :type => 'text/csv; charset=utf-8; header=present', 
        :filename => "PropertyList_#{Date.today.strftime('%m_%d_%Y')}.csv")
    end
    
    def import_xml
      import = Import.where(:type => "load_xml_property_importer", :active => true).last
      Resque.enqueue(XmlPropertyImporter, Time.now, import.id)
      render :json => {:success => true}
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
      
      def filter_properties(per_page = 20)
        arr = []
        hash = {}
        
        ["_id", "origin_id","name", "city", "state", "smartrent_status"].each do |k|
          next if params[k].blank?
          val = params[k].strip
          
          if k == "_id"
            arr << "id = :id"
            hash[:id] = "#{val}"
          elsif k == "status"
            arr << "#{k} LIKE :#{k}"
            hash[k.to_sym] = "%#{val}%"
          else
            arr << "#{k} LIKE :#{k}"
            hash[k.to_sym] = "%#{val}%"
          end
        end
        @properties = current_user.managed_properties.smartrent.where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page).order("name asc")
      end
  end
end
