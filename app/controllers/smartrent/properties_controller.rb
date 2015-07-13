require_dependency "smartrent/application_controller"

module Smartrent
  class PropertiesController < ApplicationController
    # GET /properties
    # GET /properties.json
    def index
      #@properties = Property.all
      @current_page = "properties"
      q_params = params[:q]
      q_params.delete_if {|key, value| key == "price"}
      price = Property.get_price(q_params)
      @q = Property.custom_ransack(q_params)
      #price = q_params[:price]
      properties = Property.unique_result(@q)
      #q_params[:price] = price if price.present?
      q_params[:price] = price
      properties = Property.custom_filters q_params, properties
      @properties_grouped_by_states = Smartrent::Property.grouped_by_states(properties)
  
      respond_to do |format|
        format.html # index.html.erb
        format.js {}
      end
    end
  
    # GET /properties/1
    # GET /properties/1.json
    def show
      @property = Property.find(params[:id])
  
      respond_to do |format|
        format.html # show.html.erb
        format.json { render json: @property }
      end
    end
  
    # GET /properties/new
    # GET /properties/new.json
    def new
      @property = Property.new
  
      respond_to do |format|
        format.html # new.html.erb
        format.json { render json: @property }
      end
    end
  
    # GET /properties/1/edit
    def edit
      @property = Property.find(params[:id])
    end
  
    # POST /properties
    # POST /properties.json
    def create
      @property = Property.new(property_params)
  
      respond_to do |format|
        if @property.save
          format.html { redirect_to @property, notice: 'Property was successfully created.' }
          format.json { render json: @property, status: :created, location: @property }
        else
          format.html { render action: "new" }
          format.json { render json: @property.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # PUT /properties/1
    # PUT /properties/1.json
    def update
      @property = Property.find(params[:id])
  
      respond_to do |format|
        if @property.update_attributes(property_params)
          format.html { redirect_to @property, notice: 'Property was successfully updated.' }
          format.json { head :no_content }
        else
          format.html { render action: "edit" }
          format.json { render json: @property.errors, status: :unprocessable_entity }
        end
      end
    end
  
    # DELETE /properties/1
    # DELETE /properties/1.json
    def destroy
      @property = Property.find(params[:id])
      @property.destroy
  
      respond_to do |format|
        format.html { redirect_to properties_url }
        format.json { head :no_content }
      end
    end
    
    private
      def property_params
        params.require(:property).permit!
      end
  end
end
