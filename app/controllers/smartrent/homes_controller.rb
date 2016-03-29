require_dependency "smartrent/application_controller"

module Smartrent
  class HomesController < ApplicationController
    # GET /homes
    # GET /homes.json
    def index
      @current_page = "homes"
      @homes = Home.visible.order('position asc').paginate(:page => params[:page], :per_page => 10)
      respond_to do |format|
        format.html # index.html.erb
        format.json {
          render :json => @homes.collect{|h|
            {
              title: h.title,
              description: h.description,
              address: [h.address, h.city, h.state].join(", "),
              lat: h.latitude,
              lon: h.longitude,
              image: h.image,
              image_link: home_url(h)
            }
            
          }
        }
      end
    end
    # GET /homes/1
    # GET /homes/1.json
    def show
      @current_page = "homes"
      @home = Home.includes(:more_homes => :floor_plan_images).find_by_url(params[:id])
      raise ActiveRecord::RecordNotFound if !@home
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @home }
      end
    end
  end
end
