require 'csv'
require 'net/ftp'
require Rails.root.join("lib/core_ext", "hash.rb")

module Smartrent
  class WeeklyPropertyXmlImporter
    extend Resque::Plugins::Retry
    @retry_limit = RETRY_LIMIT
    @retry_delay = RETRY_DELAY

    def self.queue
      :crm_immediate
    end

    def self.perform(time = nil)
      time = Time.parse(time) if time.kind_of?(String)
      # download xml from ftp
      
      #Floorplan contains all the floor_plans
      floor_plans_map = {
        :name => ["Name"],
        :origin_id => ["Id"],
        :url => ["FloorplanAvailabilityURL"],
        :beds => ["Bedrooms"],
        :baths => ["Bathrooms"],
        :sq_feet_max => ["SquareFeet", "Max"],
        :sq_feet_min => ["SquareFeet", "Min"],
        :rent_min => ["EffectiveRent", "Min"],
        :rent_max => ["EffectiveRent", "Max"]
      }

      property_map = {
        :origin_id => ["PropertyID" ,"Identification" ,"PrimaryID"],
        :name => ["PropertyID" ,"Identification" ,"MarketingName"],
        :website_url => ["PropertyID" ,"Identification" ,"WebSite"],
        :bozzuto_url => ["PropertyID" ,"Identification" ,"BozzutoURL"],
        :latitude => ["PropertyID" ,"Identification" ,"Latitude"],
        :longitude => ["PropertyID" ,"Identification" ,"Longitude"],
        :address_line1 => ["PropertyID" ,"Address" ,"Address1"],
        :city => ["PropertyID" ,"Address" ,"City"],
        :state => ["PropertyID" ,"Address" ,"State"],
        :zip => ["PropertyID" ,"Address" ,"PostalCode"],
        :county => ["PropertyID" ,"Address" ,"CountyName"],
        :description => ["Information" ,"OverviewText"],
        :short_description => ["Information" ,"OverviewBullet1"],
        :phone => ["PropertyID" ,"Phone" ,"PhoneNumber"],
        :image => ["Slideshow", "SlideshowImageURL", 0],
        :floor_plans => ["Floorplan"],
        :features => ["FeaturedButton"]
      }
      #FeaturedButton contains all the features
      
      Net::FTP.open('feeds.livebozzuto.com', 'Smarbozkrn', 'jtLQig4W') do |ftp|
        ftp.passive = true
        ftp.getbinaryfile("bozzuto.xml","#{TMP_DIR}bozzuto.xml")
        puts "Ftp downloaded"
      end
      
      f = File.read("#{TMP_DIR}bozzuto.xml")
      #f = File.read("/Users/tinnguyen/Desktop/_smartrent/sr-data/bozzuto.xml")
      
      total_updates = 0
      total_creates = 0
      
      properties = Hash.from_xml(f)
      properties["PhysicalProperty"]["Property"].each_with_index do |p, pndx|
        features = p.nest(property_map[:features])
        origin_id = p.nest(property_map[:origin_id]) # this is the Bozzuto Property No on BozzutoLink
        name = p.nest(property_map[:name])
        
        pp ">>> pndx: #{pndx+1}: origin_id: #{origin_id}, name: #{name}"
        
        next if !origin_id.present? || !name.present? || !features.present? || features.nil? || features.select{|f| f["Name"].downcase == 'smartrent'}.count == 0
        
        property = Smartrent::Property.find_by(:origin_id => origin_id)
        
        if !property
          property = Smartrent::Property.new 
          
          # set default attributes when the xml importer create the property record
          property.is_smartrent = true
          property.is_crm = false
          property.updated_by = "xml_feed"
        end
        
        # only update property which is allowed to be updated by xml_feed
        next if property.updated_by != "xml_feed"
        
        ActiveRecord::Base.transaction do
          property_floor_plans = []
          property_map.each do |key, value|
            if key == :features
              #pp key, value
              p.nest(value).each do |feature|
                if !Smartrent::Feature.feature_names.include?(feature["Name"])
                  Feature.create!({:name => feature["Name"]})
                end
                property.feature_ids << Feature.find_by_name(feature["Name"]).id
              end
              
            elsif key == :floor_plans
              #Due to an unexpected FloorPlan constant not found error
              #So, I'm saving it after the property is saved
              floor_plans = p.nest(property_map[key])
              
              if floor_plans.present?
                
                if floor_plans.kind_of?(Hash) 
                  floor_plans = [floor_plans] #push hash to array
                end
                
                floor_plans.each do |fp|
                  floor_plan = {}
                  floor_plans_map.each do |floor_key, floor_value|
                    #pp fp, floor_key, floor_value
                    if fp.nest(floor_value).present?
                      floor_plan[floor_key] = fp.nest(floor_value).strip
                    else
                      floor_plan[floor_key] = fp.nest(floor_value)
                    end
                  end
                  property_floor_plans << floor_plan
                end
              end
              
            else
              if key == :image
                begin
                  property.image = p.nest(value)
                rescue Exception => e
                  puts e.message
                  puts e.backtrace.inspect
                end
                
              else
                if p.nest(value).present?
                  property[key] = p.nest(value).strip
                else
                  property[key] = p.nest(value)
                end
              end
              
            end
          end
          
          if property.save
            pp "A property has been saved, ##{property.id} changes: ", property.changed_attributes
            
            if property.id_was.nil?
              total_creates += 1
            else
              total_updates += 1
            end
            
            floor_plan_ids = []
            property_floor_plans.each do |floor_plan|
              fp = Smartrent::FloorPlan.where(:property_id => property.id, :origin_id => floor_plan[:origin_id]).first
              if fp
                fp.update_attributes!(floor_plan)
              else
                fp = property.floor_plans.create(floor_plan)
              end
              
              floor_plan_ids << fp.id
            end
            
            #delete previous floor plans to use the new floorplans from the xml
            pp "deleting floorplan not IN floor_plan_ids: #{floor_plan_ids}"
            floor_plan_ids.compact!
            Smartrent::FloorPlan.where("property_id = ? AND id NOT IN (?)", property.id, floor_plan_ids).delete_all

            
          elsif !property.errors.empty?
            pp "error: ##{property.id}", property.errors.full_messages.join(", ")
          end
          
        end
      end #/ properties loop
      
      pp "total_creates: #{total_creates}, total_updates: #{total_updates}"
      
    end #/ perform
  end
  
end
