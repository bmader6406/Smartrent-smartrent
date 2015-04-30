require_dependency "smartrent/application_controller"

module Smartrent
  class FloorPlanImagesController < ApplicationController
    # GET /floor_plan_images
    # GET /floor_plan_images.json
    def index
      @floor_plan_images = FloorPlanImage.all
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @floor_plan_images }
      end
    end
  
    # GET /floor_plan_images/1
    # GET /floor_plan_images/1.json
    def show
      @floor_plan_image = FloorPlanImage.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @floor_plan_image }
      end
    end
  
    # GET /floor_plan_images/new
    # GET /floor_plan_images/new.json
    def new
      @floor_plan_image = FloorPlanImage.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @floor_plan_image }
      end
    end
  
    # GET /floor_plan_images/1/edit
    def edit
      @floor_plan_image = FloorPlanImage.find(params[:id])
    end
  
    # POST /floor_plan_images
    # POST /floor_plan_images.json
    def create
      @floor_plan_image = FloorPlanImage.new(params[:floor_plan_image])
  
      respond_to do |format|
        if @floor_plan_image.save
          format.html { redirect_to @floor_plan_image, notice: 'Floor plan image was successfully created.' }
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
      @floor_plan_image = FloorPlanImage.find(params[:id])
  
      respond_to do |format|
        if @floor_plan_image.update_attributes(params[:floor_plan_image])
          format.html { redirect_to @floor_plan_image, notice: 'Floor plan image was successfully updated.' }
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
      @floor_plan_image = FloorPlanImage.find(params[:id])
      @floor_plan_image.destroy
  
      respond_to do |format|
        format.html { redirect_to floor_plan_images_url }
        format.json { head :no_content }
      end
    end
  end
end
