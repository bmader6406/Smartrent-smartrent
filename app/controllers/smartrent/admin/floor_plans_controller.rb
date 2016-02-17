require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::FloorPlansController < Admin::AdminController
    before_action :set_property
    before_action :set_floor_plan
    
    # GET /admin/floor_plans
    # GET /admin/floor_plans.json
    def index
      filter_floor_plans
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @floor_plans }
      end
    end
  
    # GET /admin/floor_plans/1
    # GET /admin/floor_plans/1.json
    def show
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @floor_plan }
      end
    end
  
    # GET /admin/floor_plans/new
    # GET /admin/floor_plans/new.json
    def new
      @floor_plan = @property.floor_plans.new
      
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @floor_plan }
      end
    end
  
    # GET /admin/floor_plans/1/edit
    def edit
    end
  
    # POST /admin/floor_plans
    # POST /admin/floor_plans.json
    def create
      @floor_plan = @property.floor_plans.new(floor_plan_params)
  
      respond_to do |format|
        if @floor_plan.save
          format.html { redirect_to admin_property_floor_plan_url(@property, @floor_plan), notice: 'Floor plan was successfully created.' }
          format.json { render json: @floor_plan, status: :created, location: @floor_plan }
        else
          format.html { render action: "new" }
          format.json { render json: @floor_plan.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /admin/floor_plans/1
    # PUT /admin/floor_plans/1.json
    def update
      respond_to do |format|
        if @floor_plan.update_attributes(floor_plan_params)
          format.html { redirect_to admin_property_floor_plan_url(@property, @floor_plan), notice: 'Floor plan was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @floor_plan.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /admin/floor_plans/1
    # DELETE /admin/floor_plans/1.json
    def destroy
      @floor_plan.destroy
  
      respond_to do |format|
        format.html { redirect_to admin_property_floor_plans_url(@property) }
        format.json { head :no_content }
      end
    end
    
    private
    
      def floor_plan_params
        params.require(:floor_plan).permit!
      end
      
      def set_property
        @property = Smartrent::Property.find(params[:property_id])
      end
      
      def set_floor_plan
        @floor_plan = @property.floor_plans.find(params[:id]) if params[:id].present?
        case action_name
          when "create"
            authorize! :cud, Smartrent::FloorPlan
          when "edit", "update", "destroy"
            authorize! :cud, @floor_plan
          when "read"
            authorize! :read, @floor_plan
          else
            authorize! :read, Smartrent::FloorPlan
        end
      end
      
      def filter_floor_plans(per_page = 20)
        arr = []
        hash = {}
        ["_id", "origin_id", "name", "url", "sq_feet_max", "sq_feet_min", "beds", "baths", "rent_min", "rent_max", "penthouse", "studio"].each do |k|
          next if params[k].blank?
          val = params[k].strip
          case k
            when "_id"
              arr << "id = :id"
              hash[:id] = "#{val}"
              
            when "sq_feet_max", "sq_feet_min", "beds", "baths", "origin_id"
              arr << "#{k} = :#{k}"
              hash[k.to_sym] = "#{val}"
              
            when "rent_min"
              arr << "#{k} >= :#{k}"
              hash[k.to_sym] = "#{val}"
              
            when "rent_max"
              arr << "#{k} <= :#{k}"
              hash[k.to_sym] = "#{val}"

            when "penthouse", "studio"
              value = params[k] == "true" ? true : false
              arr << "#{k} = :#{k}"
              hash[k.to_sym] = value
            else
              arr << "#{k} LIKE :#{k}"
              hash[k.to_sym] = "%#{val}%"
          end
        end
        
        @floor_plans = @property.floor_plans.where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page).order("name asc")
      end
  end
end
