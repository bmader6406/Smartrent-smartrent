require_dependency "smartrent/admin/admin_controller"

module Smartrent
  class Admin::RewardsController < Admin::AdminController
    # GET /admin/rewards
    # GET /admin/rewards.json
    #
    before_action :set_reward
    
    def index
      filter_rewards
      
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

    
    private
      def set_reward
        @reward = Reward.find(params[:id]) if params[:id]
        case action_name
          when "create"
            authorize! :cud, Smartrent::Reward
          when "edit", "update", "destroy"
            authorize! :cud, @reward
          when "read"
            authorize! :read, @reward
          else
            authorize! :read, Smartrent::Reward
        end
      end
      def filter_rewards(per_page = 20)
        arr = []
        hash = {}
        
        ["_id","property_id", "resident_id", "type_", "amount", "period_start", "period_end"].each do |k|
          next if params[k].blank?
          val = params[k].strip
          if k == "_id"
            arr << "id = :id"
            hash[:id] = "#{val}"
          else
            arr << "#{k} = :#{k}"
            hash[k.to_sym] = "#{val}"
          end
        end
        
        @rewards = current_user.managed_rewards.includes(:resident, :property).where(arr.join(" AND "), hash).paginate(:page => params[:page], :per_page => per_page).order("created_at desc")
      end

      def reward_params
        params.require(:reward).permit!
      end
  end
end
