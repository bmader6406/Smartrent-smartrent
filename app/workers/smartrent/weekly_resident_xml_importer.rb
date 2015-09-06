require 'csv'
require 'net/ftp'

# - Import Residents from the ftp link and add the new properties
class Hash
  def nest(keys)
    keys.reduce(self) {|m,k| m && m[k] }
  end
end

module Smartrent
  class WeeklyResidentXmlImporter
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
        :email => ["PropertyID" ,"Address" ,"Lead2LeaseEmail"],
        :phone => ["PropertyID" ,"Phone" ,"PhoneNumber"],
        :image => ["Slideshow", "SlideshowImageURL", 0],
        :floor_plans => ["Floorplan"],
        :features => ["FeaturedButton"]
      }
      #FeaturedButton contains all the features
      
      Net::FTP.open('feeds.livebozzuto.com', 'Smarbozkrn', 'jtLQig4W') do |ftp|
        ftp.getbinaryfile("bozzuto.xml","#{TMP_DIR}bozzuto.xml")
      end
      
      f = File.read("#{TMP_DIR}bozzuto.xml")
      #f = File.read("/Users/talal/Desktop/bozzuto.xml")
      properties = Hash.from_xml(f)
      properties["PhysicalProperty"]["Property"].each do |p|
        features = p.nest(property_map[:features])
        origin_id = p.nest(property_map[:origin_id])
        name = p.nest(property_map[:name])
        next if !origin_id.present? || !name.present? || !features.present? || features.nil?
        if Property.where("origin_id = ? or name = ?", origin_id , name).count == 0 && features.select{|f| f["Name"].downcase == 'smartrent'}
          ActiveRecord::Base.transaction do
            property_floor_plans = []
            property = Smartrent::Property.new
            property.is_smartrent = true
            property_map.each do |key, value|
              if key == :features
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
                  floor_plans.each do |fp|
                    floor_plan = {}
                    floor_plans_map.each do |floor_key, floor_value|
                      floor_plan[floor_key] = fp.nest(floor_value)
                    end
                    property_floor_plans << floor_plan
                  end
                end
              else
                if key == :image
                  property.image = p.nest(value)
                else
                  property[key] = p.nest(value)
                end
              end
            end
            if property.save!
              property_floor_plans.each do |floor_plan|
                property.floor_plans.create!(floor_plan)
              end
            end
          end
        end
      end
    end
  end
end
