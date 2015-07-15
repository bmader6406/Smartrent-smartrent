require_dependency "smartrent/application_controller"

module Smartrent
  class PropertiesController < ApplicationController
    # GET /properties
    # GET /properties.json
    before_action do
      @current_page = "properties"
    end
    def index
      q_params = params[:q]
      q_params.delete_if {|key, value| key == "price"} if q_params.present?
      price = Property.get_price(q_params) if q_params.present?
      #Doing this to cater new ransack issue of not allowing custom params in q
      q_params_copy = q_params.clone if q_params.present?
      @q = Property.custom_ransack(q_params)
      properties = Property.unique_result(@q)
      q_params_copy[:price] = price if q_params.present?
      q_params_copy.delete_if {|key, value| (key == "maximum_price" or key == "minimum_price" or key == "where_one_bed" or key == "where_two_bed" or key == "where_three_more_bed" or key == "where_penthouse") and value == "0"} if q_params.present?
      properties = Property.custom_filters q_params_copy, properties
      @properties_grouped_by_states = Property.grouped_by_states(properties)

      respond_to do |format|
        format.html # index.html.erb
        format.js {}
      end
    end

    # GET /properties/1
    # GET /properties/1.json
    def show
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
      @property.destroy
      respond_to do |format|
        format.html { redirect_to properties_url }
        format.json { head :no_content }
      end
    end

    private
      def set_property
        @property = Property.find(params[:id])
        case action
          when "create"
            authorize! :cud, ::Property

          when "edit", "update", "destroy"
            authorize! :cud, @property

          else
            authorize! :read, @property
        end
      end
      def property_params
        params.require(:property).permit!
      end
  end
end
