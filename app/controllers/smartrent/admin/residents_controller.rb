require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::ResidentsController < Admin::AdminController
    # GET /admin/residents
    # GET /admin/residents.json
    def index
      @residents = Resident.all
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @residents }
      end
    end
  
    # GET /admin/residents/1
    # GET /admin/residents/1.json
    def show
      @resident = Resident.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @resident }
      end
    end
  
    # GET /admin/residents/new
    # GET /admin/residents/new.json
    def new
      @resident = Resident.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @resident }
      end
    end
  
    # GET /admin/residents/1/edit
    def edit
      @resident = Resident.find(params[:id])
    end
  
    # POST /admin/residents
    # POST /admin/residents.json
    def create
      @resident = Resident.new(params[:resident])
  
      respond_to do |format|
        if @resident.save
          format.html { redirect_to @resident, notice: 'Resident was successfully created.' }
          format.json { render json: @resident, status: :created, location: @resident }
        else
          format.html { render action: "new" }
          format.json { render json: @resident.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /admin/residents/1
    # PUT /admin/residents/1.json
    def update
      @resident = Resident.find(params[:id])
  
      respond_to do |format|
        if @resident.update_attributes(params[:resident])
          format.html { redirect_to @resident, notice: 'Resident was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @resident.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /admin/residents/1
    # DELETE /admin/residents/1.json
    def destroy
      @resident = Resident.find(params[:id])
      @resident.destroy
  
      respond_to do |format|
        format.html { redirect_to residents_url }
        format.json { head :no_content }
      end
    end
  end
end
