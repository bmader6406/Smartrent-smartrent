require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::FeaturesController < Admin::AdminController
    before_action :require_admin, :only => [:import, :import_page]
    before_action :set_feature

    # GET /admin/features
    # GET /admin/features.json
    def index
      filter_features
      
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @features }
      end
    end
  
    # GET /admin/features/new
    # GET /admin/features/new.json
    def new
      @feature = Feature.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @feature }
      end
    end
  
    # GET /admin/features/1/edit
    def edit
    end
  
    # POST /admin/features
    # POST /admin/features.json
    def create
      @feature = Feature.new(admin_feature_params)
  
      respond_to do |format|
        if @feature.save
          format.html { redirect_to admin_features_url, notice: 'Feature was successfully created.' }
          format.json { render json: @feature, status: :created, location: @feature }
        else
          format.html { render action: "new" }
          format.json { render json: @feature.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /admin/features/1
    # PUT /admin/features/1.json
    def update
      respond_to do |format|
        if @feature.update_attributes(admin_feature_params)
          format.html { redirect_to admin_features_url, notice: 'Feature was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @feature.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /admin/features/1
    # DELETE /admin/features/1.json
    def destroy
      @feature.destroy
  
      respond_to do |format|
        format.html { redirect_to admin_features_url }
        format.json { head :no_content }
      end
    end
    def import_page
      render :import
    end
    def import
      Feature.import(params[:file])
      redirect_to admin_features_path, notice: "Features have been imported"
    end
    
    private
    
      def admin_feature_params
        params.require(:feature).permit!
      end

      def set_feature
        @feature = Feature.find(params[:id]) if params[:id]
        case action_name
          when "create"
            authorize! :cud, Smartrent::Feature
          when "edit", "update", "destroy"
            authorize! :cud, @feature
          when "read"
            authorize! :read, @feature
          else
            authorize! :read, Smartrent::Feature
        end
      end
      def filter_features(per_page = 20)
        arr = []
        hash = {}
        
        ["_id","name"].each do |k|
          next if params[k].blank?
          val = params[k].strip
          if k == "_id"
            arr << "id = :id"
            hash[:id] = "#{val}"
          else
            arr << "#{k} LIKE :#{k}"
            hash[k.to_sym] = "%#{val}%"
          end
        end
        @features = Feature.where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page).order("name asc")
      end
      
  end
end
