require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::HomesController < Admin::AdminController
    # GET /homes
    # GET /homes.json
    before_action :set_home

    def index
      @active = "homes"
      @homes = Home.paginate(:page => params[:page], :per_page => 10)
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @homes }
      end
    end
  
    # GET /homes/1
    # GET /homes/1.json
    def show
      @active = "homes"
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @home }
      end
    end
  
    # GET /homes/new
    # GET /homes/new.json
    def new
      @active = "homes"
      @home = Home.new
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @home }
      end
    end
  
    # GET /homes/1/edit
    def edit
      @active = "homes"
    end
  
    # POST /homes
    # POST /homes.json
    def create
      @home = Home.new(home_params)
      respond_to do |format|
        if @home.save
          format.html { redirect_to admin_home_path(@home), notice: 'Home was successfully created.' }
          format.json { render json: @home, status: :created, location: @home }
        else
          format.html { render action: "new" }
          format.json { render json: @home.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /homes/1
    # PUT /homes/1.json
    def update
      respond_to do |format|
        if @home.update_attributes(home_params)
          format.html { redirect_to admin_home_path(@home), notice: 'Home was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @home.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /homes/1
    # DELETE /homes/1.json
    def destroy
      @home.destroy
      respond_to do |format|
        format.html { redirect_to admin_homes_url }
        format.json { head :no_content }
      end
    end

    def import_page
      @active = "homes"
      render :import
    end

    def import
      Home.import(params[:file])
      redirect_to admin_homes_path, notice: "Homes imported."
    end

    def set_home
      @home = Home.find(params[:id]) if params[:id]
    end
    
    private
    
      def home_params
        params.require(:home).permit!
      end
      
  end
end
