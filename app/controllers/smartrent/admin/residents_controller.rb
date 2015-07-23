require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::ResidentsController < Admin::AdminController
    before_filter :authenticate_admin!, :only => [:import, :import_page]
    before_action :set_resident

    # GET /admin/residents
    # GET /admin/residents.json
    before_action do
      @active = "residents"
    end

    def index
      #@residents = current_user.managed_residents.paginate(:page => params[:page], :per_page => 15)
      filter_residents

      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @residents }
      end
    end

    # GET /admin/residents/1
    # GET /admin/residents/1.json
    def show
      if @resident.is_smartrent?
        @resident_rewards = @resident.rewards.paginate(:page => params[:page], :per_page => 10)
      end
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @resident }
      end
    end
    def properties
      @resident_properties = @resident.resident_properties.paginate(:page => params[:page], :per_page => 15)
    end
    def rewards
      @rewards = @resident.rewards.paginate(:page => params[:page], :per_page => 15)
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
    end

    def archive
      @resident.archive
      redirect_to [:admin, @resident], notice: 'Resident has been successfully archived.'
    end
  
    # POST /admin/residents
    # POST /admin/residents.json
    def create
      @resident = Resident.new(resident_params)
  
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

    def move_all_rewards_to_initial_balance
      Resident.move_all_rewards_to_initial_balance(current_user.managed_residents)
      redirect_to admin_rewards_path, :notive => "All Residents rewards have been set as initial reward"
    end
  
    # PUT /admin/residents/1
    # PUT /admin/residents/1.json
    def update
      respond_to do |format|
        if @resident.update_attributes(resident_params)
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

    def import_page
      render :import
    end

    def import
      Resident.import(params[:file])
      redirect_to admin_residents_path, notice: "Residents have been imported"
    end
    
    private

    def set_resident
      @resident = Resident.find(params[:id]) if params[:id]
      case action_name
        when "create"
          authorize! :cud, ::Resident
        when "edit", "update", "destroy"
          authorize! :cud, @resident
        when "read"
          authorize! :read, @resident
        else
          authorize! :read, ::Resident
      end
    end

    def resident_params
      params.require(:resident).permit!
    end
    def filter_residents(per_page = 15)
      arr = []
      hash = {}
      
      ["id","name", "email", "property_id", "status"].each do |k|
        next if params[k].blank?
        if k == "_id"
          arr << "id = :id"
          hash[:id] = "#{params[k]}"
        else
          arr << "#{k} LIKE :#{k}"
          hash[k.to_sym] = "%#{params[k]}%"
        end
      end
      @residents = current_user.managed_residents.where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page).order("name asc")
    end
  end
end
