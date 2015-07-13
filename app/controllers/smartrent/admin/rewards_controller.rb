require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::RewardsController < Admin::AdminController
    # GET /admin/rewards
    # GET /admin/rewards.json
    #
    before_action :set_reward
    before_action do
      @active = "rewards"
    end
    def index
      @rewards = Reward.paginate(:page => params[:page], :per_page => 15).order(:created_at)
  
      respond_to do |format|
        format.html # index.html.erb
        format.json { render json: @rewards }
      end
    end
  
    # GET /admin/rewards/1
    # GET /admin/rewards/1.json
    def show
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @reward }
      end
    end
  
    # GET /admin/rewards/new
    # GET /admin/rewards/new.json
    def new
      @reward = Reward.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @reward }
      end
    end
  
    # GET /admin/rewards/1/edit
    def edit
    end

    # POST /admin/rewards
    # POST /admin/rewards.json
    def create
      @reward = Reward.new(reward_params)
  
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
  
    # PUT /admin/rewards/1
    # PUT /admin/rewards/1.json
    def update
      respond_to do |format|
        if @reward.update_attributes(reward_params)
          format.html { redirect_to admin_reward_path(@reward), notice: 'Reward was successfully updated.' }
          format.json { head :no_content }
          format.js {}
        else
          format.html { render action: "edit" }
          format.json { render json: @reward.errors, status: :unprocessable_entity }
          format.js {}
        end
      end
    end

  
    # DELETE /admin/rewards/1
    # DELETE /admin/rewards/1.json
    def destroy
      @reward.destroy
      respond_to do |format|
        format.html { redirect_to admin_rewards_url }
        format.json { head :no_content }
      end
    end

    def import_page
      render :import
    end

    def import
      Reward.import(params[:file])
      redirect_to admin_rewards_path, notice: "Rewards have been imported"
    end

    def set_reward
      @reward = Reward.find(params[:id]) if params[:id]
    end
    
    private
    
      def reward_params
        params.require(:reward).permit!
      end
  end
end
