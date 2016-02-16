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
      q_params_copy = nil
      
      if q_params
        q_params.delete_if {|key, value| key == "price"}
        price = Property.get_price(q_params)
        
        #Doing this to cater new ransack issue of not allowing custom params in q
        q_params_copy = q_params.clone
        
        q_params_copy[:price] = price
        q_params_copy.delete_if {|key, value| 
          [ "maximum_price", "minimum_price", "where_one_bed", "where_two_bed", 
            "where_three_more_bed", "where_penthouse", "where_studio", "matches_all_features" ].include?(key) &&  value == "0"
        }
      end
            
      @q = Property.smartrent.custom_ransack(q_params)

      properties = Property.custom_filters(q_params_copy, @q.result.uniq)

      @properties_grouped_by_states = grouped_by_states(properties)

      respond_to do |format|
        format.html # index.html.erb
        format.js {}
        format.json {
          render :json => properties.collect{|p|
            {
              title: p.name,
              description: p.short_description,
              address: [p.address_line1, p.city, p.state].join(", "),
              lat: p.latitude,
              lon: p.longitude,
              image: p.image,
              image_link: p.bozzuto_url
            }
          }
        }
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
    
    protected
    
      def grouped_by_states(properties)
        states = {}
        properties.each do |property|
          state = property.state #.to_s.downcase
          next if !state
          states[state] ||= {}
          states[state]["cities"] ||= {}
          states[state]["cities"][property.city] ||= 0
          states[state]["cities"][property.city] +=1
          states[state]["counties"] ||= {}
          if property.county
            states[state]["counties"][property.county] ||= 0
            states[state]["counties"][property.county] +=1
          end
          states[state]["properties"] ||= []
          states[state]["properties"].push property
          states[state]["total"] ||= 0
          states[state]["total"] +=1
        end
        states
        states.sort{|a,b| a[0].downcase <=> b[0].downcase}
      end

  end
end
