require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::MoreHomesController < Admin::AdminController
    # GET /admin/more_more_homes
    # GET /admin/more_more_homes.json
    #
    before_action :require_admin, :only => [:import, :import_page]
    before_action :set_home
    before_action :set_more_home
    
    def index
      @more_homes = @home.more_homes.paginate(:page => params[:page], :per_page => 15).order("position asc")
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @more_more_homes }
      end
    end
  
    # GET /admin/more_more_homes/1
    # GET /admin/more_more_homes/1.json
    def show
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @more_home }
      end
    end
  
    # GET /admin/more_more_homes/new
    # GET /admin/more_more_homes/new.json
    def new
      @more_home = @home.more_homes.new
      #3.times { @more_home.floor_plan_images.build }
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @more_home }
      end
    end
  
    # GET /admin/more_more_homes/1/edit
    def edit
    end

    # POST /admin/more_more_homes
    # POST /admin/more_more_homes.json
    def create
      @more_home = @home.more_homes.new(more_home_params)
      respond_to do |format|
        if @more_home.save
          format.html { redirect_to [:admin, @home, @more_home], notice: 'More Home was successfully created.' }
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
      pp "more_home_params:", more_home_params
      respond_to do |format|
        if @more_home.update_attributes(more_home_params)
          format.html { redirect_to admin_home_more_home_url(@home, @more_home), notice: 'More Home was successfully updated.' }
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
        format.html { redirect_to admin_home_more_homes_url(@home) }
        format.json { head :no_content }
      end
    end

    private
      def more_home_params
        params.require(:more_home).permit!
      end
      
      def set_home
        @home = Smartrent::Home.find_by_url(params[:home_id])
      end
      
      def set_more_home
        @more_home = @home.more_homes.find(params[:id]) if params[:id]
        
        case action_name
          when "create"
            authorize! :cud, Smartrent::MoreHome
          when "edit", "update", "destroy"
            authorize! :cud, @more_home
          when "read"
            authorize! :read, @more_home
          else
            authorize! :read, Smartrent::MoreHome
        end
      end
  end
end
