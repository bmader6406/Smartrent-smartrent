require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::FeaturesController < Admin::AdminController
    before_filter :authenticate_admin!
    # GET /admin/features
    # GET /admin/features.json
    def index
      @active = "properties"
      @admin_features = Feature.paginate(:page => params[:page], :per_page => 15)
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @admin_features }
      end
    end
  
    # GET /admin/features/new
    # GET /admin/features/new.json
    def new
      @active = "properties"
      @admin_feature = Feature.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @admin_feature }
      end
    end
  
    # GET /admin/features/1/edit
    def edit
      @active = "properties"
      @admin_feature = Feature.find(params[:id])
    end
  
    # POST /admin/features
    # POST /admin/features.json
    def create
      @admin_feature = Feature.new(admin_feature_params)
  
      respond_to do |format|
        if @admin_feature.save
          format.html { redirect_to admin_features_url, notice: 'Feature was successfully created.' }
          format.json { render json: @admin_feature, status: :created, location: @admin_feature }
        else
          format.html { render action: "new" }
          format.json { render json: @admin_feature.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /admin/features/1
    # PUT /admin/features/1.json
    def update
      @admin_feature = Feature.find(params[:id])
  
      respond_to do |format|
        if @admin_feature.update_attributes(admin_feature_params)
          format.html { redirect_to admin_features_url, notice: 'Feature was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @admin_feature.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /admin/features/1
    # DELETE /admin/features/1.json
    def destroy
      @admin_feature = Feature.find(params[:id])
      @admin_feature.destroy
  
      respond_to do |format|
        format.html { redirect_to admin_features_url }
        format.json { head :no_content }
      end
    end
    def import_page
      @active = "properties"
      render :import
    end
    def import
      Feature.import(params[:file])
      redirect_to admin_features_path, notice: "Features have been imported"
    end
    
    private
    
      def admin_feature_params
        params.require(:admin_feature).permit!
      end
      
  end
end
