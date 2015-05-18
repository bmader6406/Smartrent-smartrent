require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::ResidentsController < Admin::AdminController
    before_filter :set_resident

    # GET /admin/residents
    # GET /admin/residents.json
    def index
      @active = "residents"
      @residents = Resident.paginate(:page => params[:page], :per_page => 15)
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @residents }
      end
    end
  
    # GET /admin/residents/1
    # GET /admin/residents/1.json
    def show
      @active = "residents"
      @resident_rewards = @resident.rewards.paginate(:page => params[:page], :per_page => 10)
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @resident }
      end
    end
  
    # GET /admin/residents/new
    # GET /admin/residents/new.json
    def new
      @active = "residents"
      @resident = Resident.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @resident }
      end
    end
  
    # GET /admin/residents/1/edit
    def edit
      @active = "residents"
      @resident = Resident.find(params[:id])
    end

    def archive
      @resident.archive
      redirect_to [:admin, @resident], notice: 'Resident has been successfully archived.'
    end
  
    # POST /admin/residents
    # POST /admin/residents.json
    def create
      @resident = Resident.new(params[:resident])
  
      respond_to do |format|
        if @resident.save
          format.html { redirect_to [:admin, @resident], notice: 'Resident was successfully created.' }
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
          format.html { redirect_to admin_resident_path(@resident), notice: 'Resident was successfully updated.' }
          format.json { head :no_content }
          format.js {}
        else
          format.html { render action: "edit" }
          format.json { render json: @resident.errors, status: :unprocessable_entity }
          format.js {}
        end
      end
    end
  
    # DELETE /admin/residents/1
    # DELETE /admin/residents/1.json
    def destroy
      @resident.destroy
      respond_to do |format|
        format.html { redirect_to admin_residents_url }
        format.json { head :no_content }
      end
    end
    def send_password_reset_information
      @resident.send_reset_password_instructions
      respond_to do |format|
        format.html {redirect_to admin_resident_path(@resident), :notice => "The password reset information have been sent to the email"}
        format.js {}
      end
      
    end
    def set_resident
      @resident = Resident.find(params[:id]) if params[:id]
    end
    def import_page
      @active = "residents"
      render :import
    end
    def import
      Resident.import(params[:file])
      redirect_to admin_residents_path, notice: "Residents have been imported"
    end
  end


end
