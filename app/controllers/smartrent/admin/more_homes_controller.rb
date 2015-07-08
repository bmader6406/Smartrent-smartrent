require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::MoreHomesController < Admin::AdminController
    # GET /admin/more_more_homes
    # GET /admin/more_more_homes.json
    #
    before_action :set_more_home
    def index
      @active = "homes"
      @more_homes = MoreHome.paginate(:page => params[:page], :per_page => 15).order(:created_at)
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @more_more_homes }
      end
    end
  
    # GET /admin/more_more_homes/1
    # GET /admin/more_more_homes/1.json
    def show
      @active = "homes"
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @more_home }
      end
    end
  
    # GET /admin/more_more_homes/new
    # GET /admin/more_more_homes/new.json
    def new
      @active = "homes"
      @more_home = MoreHome.new
      #3.times { @more_home.floor_plan_images.build }
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @more_home }
      end
    end
  
    # GET /admin/more_more_homes/1/edit
    def edit
      @active = "homes"
      @more_home = MoreHome.find(params[:id])
    end

    # POST /admin/more_more_homes
    # POST /admin/more_more_homes.json
    def create
      @more_home = MoreHome.new(more_home_params)
  
      respond_to do |format|
        if @more_home.save
          format.html { redirect_to [:admin, @more_home], notice: 'MoreHome was successfully created.' }
          format.json { render json: @more_home, status: :created, location: @more_home }
        else
          format.html { render action: "new" }
          format.json { render json: @more_home.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /admin/more_more_homes/1
    # PUT /admin/more_more_homes/1.json
    def update
      @more_home = MoreHome.find(params[:id])
  
      respond_to do |format|
        if @more_home.update_attributes(more_home_params)
          format.html { redirect_to admin_more_home_path(@more_home), notice: 'MoreHome was successfully updated.' }
          format.json { head :no_content }
          format.js {}
        else
          format.html { render action: "edit" }
          format.json { render json: @more_home.errors, status: :unprocessable_entity }
          format.js {}
        end
      end
    end
  
    # DELETE /admin/more_more_homes/1
    # DELETE /admin/more_more_homes/1.json
    def destroy
      @more_home.destroy
      respond_to do |format|
        format.html { redirect_to admin_more_homes_url }
        format.json { head :no_content }
      end
    end

    def import_page
      @active = "homes"
      render :import
    end

    def import
      MoreHome.import(params[:file])
      redirect_to admin_more_homes_path, notice: "more_more_homes have been imported"
    end

    def set_more_home
      @more_home = MoreHome.find(params[:id]) if params[:id]
    end
    
    private
    
      def more_home_params
        params.require(:more_home).permit!
      end
  end
end
