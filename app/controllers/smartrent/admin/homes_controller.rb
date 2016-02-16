require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::HomesController < Admin::AdminController
    # GET /homes
    # GET /homes.json
    before_action :require_admin
    before_action :set_home

    def index
      filter_homes
      
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @homes }
      end
    end
  
    # GET /homes/1
    # GET /homes/1.json
    def show
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @home }
      end
    end
  
    # GET /homes/new
    # GET /homes/new.json
    def new
      @home = Home.new
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @home }
      end
    end
  
    # GET /homes/1/edit
    def edit
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
      render :import
    end

    def import
      Home.import(params[:file])
      redirect_to admin_homes_path, notice: "Homes imported."
    end

    
    private
      def home_params
        params.require(:home).permit!
      end
      def filter_homes(per_page = 15)
        arr = []
        hash = {}
        
        ["_id", "title", "phone_number", "state", "latitude", "longitude"].each do |k|
          next if params[k].blank?
          case k
            when "_id"
              arr << "id = :id"
              hash[:id] = "#{params[k]}"
            when "latitude", "longitude"
              arr << "#{k} = :#{k}"
              hash[k.to_sym] = "#{params[k]}"
            else
              arr << "#{k} LIKE :#{k}"
              hash[k.to_sym] = "%#{params[k]}%"
          end
        end
        @homes = Home.where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page).order("position asc")
      end
      def set_home
        @home = Home.find_by_url(params[:id]) if params[:id].present?
      end
  end
end
