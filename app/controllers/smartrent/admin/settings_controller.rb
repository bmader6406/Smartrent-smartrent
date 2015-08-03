require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::SettingsController < Admin::AdminController
    before_action :set_setting
    
    def index
      @settings = Setting.paginate(:page => params[:page], :per_page => 15)
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @settings }
      end
    end
  
    # GET /settings/1
    # GET /settings/1.json
    def show
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @setting }
      end
    end
  
    # GET /settings/new
    # GET /settings/new.json
    def new
      @setting = Setting.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @setting }
      end
    end
  
    # GET /settings/1/edit
    def edit
      @setting = Setting.find(params[:id])
    end
  
    # POST /settings
    # POST /settings.json
    def create
      @setting = Setting.new(setting_params)
  
      respond_to do |format|
        if @setting.save
          format.html { redirect_to admin_setting_path(@setting), notice: 'Setting was successfully created.' }
          format.json { render json: @setting, status: :created, location: @setting }
        else
          format.html { render action: "new" }
          format.json { render json: @setting.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /settings/1
    # PUT /settings/1.json
    def update
      respond_to do |format|
        if @setting.update_attributes(setting_params)
          format.html { redirect_to admin_setting_path(@setting), notice: 'Setting was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @setting.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /settings/1
    # DELETE /settings/1.json
    def destroy
      @setting.destroy
  
      respond_to do |format|
        format.html { redirect_to admin_settings_url }
        format.json { head :no_content }
      end
    end
    
    private
    
      def setting_params
        params.require(:setting).permit!
      end
      def set_setting
        @setting = Setting.find(params[:id]) if params[:id].present?
        case action_name
          when "create"
            authorize! :cud, Smartrent::Setting
          when "edit", "update", "destroy"
            authorize! :cud, @setting
          when "read"
            authorize! :read, @setting
          else
            authorize! :read, Smartrent::Setting
        end
      end
  end
end
