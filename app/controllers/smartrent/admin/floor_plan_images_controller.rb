require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::FloorPlanImagesController < Admin::AdminController
    # GET /floor_plan_images
    # GET /floor_plan_images.json
    before_action :set_home
    before_action :set_more_home
    before_action :set_floor_plan_image

    def index
      @floor_plan_images = @more_home.floor_plan_images.paginate(:page => params[:page], :per_page => 15)
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @floor_plan_images }
      end
    end
  
    # GET /floor_plan_images/1
    # GET /floor_plan_images/1.json
    def show
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @floor_plan_image }
      end
    end
  
    # GET /floor_plan_images/new
    # GET /floor_plan_images/new.json
    def new
      @floor_plan_image = @more_home.floor_plan_images.new
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @floor_plan_image }
      end
    end
  
    # GET /floor_plan_images/1/edit
    def edit
    end
  
    # POST /floor_plan_images
    # POST /floor_plan_images.json
    def create
      @floor_plan_image = @more_home.floor_plan_images.new(floor_plan_image_params)
      respond_to do |format|
        if @floor_plan_image.save
          format.html { redirect_to admin_home_more_home_floor_plan_image_url(@home, @more_home, @floor_plan_image), notice: 'Floor plan image was successfully created.' }
          format.json { render json: @floor_plan_image, status: :created, location: @floor_plan_image }
        else
          format.html { render action: "new" }
          format.json { render json: @floor_plan_image.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /floor_plan_images/1
    # PUT /floor_plan_images/1.json
    def update
      respond_to do |format|
        if @floor_plan_image.update_attributes(floor_plan_image_params)
          format.html { redirect_to admin_home_more_home_floor_plan_image_url(@home, @more_home, @floor_plan_image), notice: 'Floor plan image was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @floor_plan_image.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /floor_plan_images/1
    # DELETE /floor_plan_images/1.json
    def destroy
      @floor_plan_image.destroy
      respond_to do |format|
        format.html { redirect_to admin_home_more_home_floor_plan_images_url(@home, @more_home) }
        format.json { head :no_content }
      end
    end
    
    private
    
      def floor_plan_image_params
        params.require(:floor_plan_image).permit!
      end
      
      def set_home
        @home = Smartrent::Home.find_by_url(params[:home_id])
      end
      
      def set_more_home
        @more_home = @home.more_homes.find(params[:more_home_id])
      end
      
      def set_floor_plan_image
        @floor_plan_image = @more_home.floor_plan_images.find(params[:id]) if params[:id].present?
        
        case action_name
          when "create"
            authorize! :cud, Smartrent::FloorPlanImage
          when "edit", "update", "destroy"
            authorize! :cud, @floor_plan_image
          when "read"
            authorize! :read, @floor_plan_image
          else
            authorize! :read, Smartrent::FloorPlanImage
        end
      end
      
  end
end
