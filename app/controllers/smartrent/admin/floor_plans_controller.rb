require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::FloorPlansController < Admin::AdminController
    # GET /admin/floor_plans
    # GET /admin/floor_plans.json
    def index
      @active = "residents"
      @admin_floor_plans = FloorPlan.paginate(:page => params[:page], :per_page => 15)
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @admin_floor_plans }
      end
    end
  
    # GET /admin/floor_plans/1
    # GET /admin/floor_plans/1.json
    def show
      @admin_floor_plan = FloorPlan.find(params[:id])
      @active = "properties"
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @admin_floor_plan }
      end
    end
  
    # GET /admin/floor_plans/new
    # GET /admin/floor_plans/new.json
    def new
      @admin_floor_plan = FloorPlan.new
      @active = "properties"
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @admin_floor_plan }
      end
    end
  
    # GET /admin/floor_plans/1/edit
    def edit
      @active = "properties"
      @admin_floor_plan = FloorPlan.find(params[:id])
    end
  
    # POST /admin/floor_plans
    # POST /admin/floor_plans.json
    def create
      @admin_floor_plan = FloorPlan.new(floor_plan_params)
  
      respond_to do |format|
        if @admin_floor_plan.save
          format.html { redirect_to admin_floor_plan_path(@admin_floor_plan), notice: 'Floor plan was successfully created.' }
          format.json { render json: @admin_floor_plan, status: :created, location: @admin_floor_plan }
        else
          format.html { render action: "new" }
          format.json { render json: @admin_floor_plan.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /admin/floor_plans/1
    # PUT /admin/floor_plans/1.json
    def update
      @admin_floor_plan = FloorPlan.find(params[:id])
  
      respond_to do |format|
        if @admin_floor_plan.update_attributes(floor_plan_params)
          format.html { redirect_to admin_floor_plan_path(@admin_floor_plan), notice: 'Floor plan was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @admin_floor_plan.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /admin/floor_plans/1
    # DELETE /admin/floor_plans/1.json
    def destroy
      @admin_floor_plan = FloorPlan.find(params[:id])
      @admin_floor_plan.destroy
  
      respond_to do |format|
        format.html { redirect_to admin_floor_plans_url }
        format.json { head :no_content }
      end
    end
    def import_page
      @active = "properties"
      render :import
    end

    def import
      FloorPlan.import(params[:file])
      redirect_to admin_floor_plans_path, notice: "Floor Plans have been imported"
    end
    
    private
    
      def floor_plan_params
        params.require(:floor_plan).permit!
      end
  end
end
