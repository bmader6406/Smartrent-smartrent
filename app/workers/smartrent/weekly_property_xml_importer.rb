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
        #:email => ["PropertyID" ,"Address" ,"Lead2LeaseEmail"], # don't set property email as Lead2LeaseEmail
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
      
      #f = File.read("/Users/talal/Desktop/bozzuto.xml")
      properties = Hash.from_xml(f)
      properties["PhysicalProperty"]["Property"].each do |p|
        features = p.nest(property_map[:features])
        origin_id = p.nest(property_map[:origin_id])
        name = p.nest(property_map[:name])
        next if !origin_id.present? || !name.present? || !features.present? || features.nil? || features.select{|f| f["Name"].downcase == 'smartrent'}.count == 0
        property = Smartrent::Property.where("lower(name) = ?", name.downcase).first
        property = Smartrent::Property.new if !property
        #next if property.id.present? && property.updated_by == "xml_feed"
        ActiveRecord::Base.transaction do
          property_floor_plans = []
          property_map.each do |key, value|
            if key == :features
              p.nest(value).each do |feature|
                if !Smartrent::Feature.feature_names.include?(feature["Name"])
                  Feature.create!({:name => feature["Name"]})
                end
                property.feature_ids << Feature.find_by_name(feature["Name"]).id
              end
            elsif key == :floor_plans
              #Destroying previous floor plans to use only these floor plans
              if property.id.nil?
                property.floor_plans.destroy_all
              end
              #Due to an unexpected FloorPlan constant not found error
              #So, I'm saving it after the property is saved
              floor_plans = p.nest(property_map[key])
              if floor_plans.present?
                floor_plans.each do |fp|
                  floor_plan = {}
                  floor_plans_map.each do |floor_key, floor_value|
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
                  #property.image = p.nest(value)
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
          property.is_smartrent = true
          property.is_crm = false if !property.id.present?
          property.updated_by = "xml_feed"
          if property.save!
            puts "A property has been saved"
            property_floor_plans.each do |floor_plan|
              fp = Smartrent::FloorPlan.where(:property_id => property.id, :origin_id => floor_plan[:origin_id]).first
              if fp
                fp.update_attributes!(floor_plan)
              else
                property.floor_plans.create!(floor_plan)
              end
            end
          end
        end
      end
    end
  end
end
