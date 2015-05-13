require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::RewardsController < Admin::AdminController
    # GET /admin/residents
    # GET /admin/residents.json
    #
    before_filter :set_reward
    def index
      @active = "rewards"
      @rewards = Reward.paginate(:page => params[:page], :per_page => 15).order(:created_at)
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @rewards }
      end
    end
  
    # GET /admin/residents/1
    # GET /admin/residents/1.json
    def show
      @active = "rewards"
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @reward }
      end
    end
  
    # GET /admin/residents/new
    # GET /admin/residents/new.json
    def new
      @active = "rewards"
      @reward = Reward.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @reward }
      end
    end
  
    # GET /admin/residents/1/edit
    def edit
      @active = "rewards"
      @reward = Reward.find(params[:id])
    end

    # POST /admin/residents
    # POST /admin/residents.json
    def create
      @reward = Reward.new(params[:reward])
  
      respond_to do |format|
        if @reward.save
          format.html { redirect_to [:admin, @reward], notice: 'Reward was successfully created.' }
          format.json { render json: @reward, status: :created, location: @reward }
        else
          format.html { render action: "new" }
          format.json { render json: @reward.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /admin/residents/1
    # PUT /admin/residents/1.json
    def update
      @reward = Reward.find(params[:id])
  
      respond_to do |format|
        if @reward.update_attributes(params[:resident])
          format.html { redirect_to admin_resident_path(@reward), notice: 'Reward was successfully updated.' }
          format.json { head :no_content }
          format.js {}
        else
          format.html { render action: "edit" }
          format.json { render json: @reward.errors, status: :unprocessable_entity }
          format.js {}
        end
      end
    end
  
    # DELETE /admin/residents/1
    # DELETE /admin/residents/1.json
    def destroy
      @reward.destroy
      respond_to do |format|
        format.html { redirect_to admin_rewards_url }
        format.json { head :no_content }
      end
    end

    def import_page
      @active = "rewards"
      render :import
    end

    def import
      Reward.import(params[:file])
      redirect_to admin_rewards_path, notice: "Rewards have been imported"
    end

    def set_reward
      @reward = Reward.find(params[:id]) if params[:id]
    end
  end
end
