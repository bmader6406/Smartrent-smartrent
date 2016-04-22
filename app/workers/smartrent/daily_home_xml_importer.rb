require 'csv'
require 'open-uri'

require Rails.root.join("lib/core_ext", "hash.rb")

module Smartrent
  class DailyHomeXmlImporter
    extend Resque::Plugins::Retry
    @retry_limit = RETRY_LIMIT
    @retry_delay = RETRY_DELAY

    def self.queue
      :crm_immediate
    end

    def self.perform(time)
      time = Time.parse(time) if time.kind_of?(String)

      home_map = {
        :title => ["SubdivisionName"],
        :url => ["SubdivisionNumber"],
        :address => ["SalesOffice", "Address", "Street1"],
        :city => ["SalesOffice", "Address", "City"],
        :state => ["SalesOffice", "Address", "State"],
        :postal_code => ["SalesOffice", "Address", "ZIP"],
        :phone_number => ["SalesOffice", "Phone"],
        :latitude => ["SalesOffice", "Address", "Geocode", "Latitude"],
        :longitude => ["SalesOffice", "Address", "Geocode", "Longitude"],
        :website => ["SubWebsite"],
        :video_url => ["SubVideoFile"],
        :description => ["SubDescription"],
        :image => ["SubImage", 0], # get the first image
        :floor_plans => ["Plan"]
      }
      
      # note: not in the feed
      # - featured floor plan
      # - home sub title
      # - home page desc
      # - search page desc
      
      more_home_map = {
        :name => ["PlanName"],
        :beds => ["Bedrooms"],
        :baths => ["Baths"],
        :sq_ft => ["BaseSqft"],
        :floor_plan_images => ["PlanImages", "FloorPlanImage"]
      }
      
      file_contents  = open('http://bozzutofeed.qburst.com/reporting/bhi_feed/XMLFeed.xml') {|f| f.read }
      
      # we can use nokogiri to parse xml file if from_xml does not work
      homes = Hash.from_xml(file_contents)
      
      total_updates = 0
      total_creates = 0
      total_ok = 0
      home_ids = []
      
      homes["Builders"]["Corporation"]["Builder"]["Subdivision"].each_with_index do |sub, i|
        url = sub.nest(home_map[:url]).to_s.parameterize
        title = sub.nest(home_map[:title])
        
        pp ">>> i: #{i+1}: url: #{url}, title: #{title}"

        total_ok += 1
        pp ">>>>>>>>> OK: #{total_ok}"
        
        home = Smartrent::Home.find_by(:url => url)
        
        if !home
          home = Smartrent::Home.new
          home.updated_by = "xml_feed"
        end
        
        # only update home which is allowed to be updated by xml_feed
        next if !["xml_feed"].include?(home.updated_by)
        
        ActiveRecord::Base.transaction do
          more_homes = []
          
          home_map.each do |key, value|
            if key == :floor_plans
              floor_plans = sub.nest(home_map[key])
              
              if floor_plans.present?
                if floor_plans.kind_of?(Hash) 
                  floor_plans = [floor_plans] #push hash to array
                end
                
                floor_plans.each do |fp|
                  more_home = {}
                  more_home_map.each do |fk, fv|
                    #pp fp, fk, fv
                    if fk == :floor_plan_images
                      more_home[:fp_images] = fp.nest(fv) || []
                      
                      if more_home[:fp_images].kind_of?(String) 
                        more_home[:fp_images] = [ more_home[:fp_images] ]
                      end
                      
                    elsif fp.nest(fv).present?
                      more_home[fk] = fp.nest(fv).strip
                      
                    else
                      more_home[fk] = fp.nest(fv)
                    end
                    
                  end
                  
                  more_homes << more_home
                end
              end
          
            elsif key == :phone_number
              phone = sub.nest(home_map[key])
              home.phone_number = "#{phone["AreaCode"]}.#{phone["Prefix"]}.#{phone["Suffix"]}"
              
            elsif key == :url
              home.url = url
              
            elsif key == :description
              home.description = sub.nest(value) if home.description.blank? # don't override description
              
            elsif key == :image
              
              begin
                home.image = sub.nest(value) if !home.image_file_name # don't override featured image
              rescue Exception => e
                pp "saving home image..."
                pp e.message
                pp e.backtrace.inspect
              end
              
            else
              if sub.nest(value).present?
                home[key] = sub.nest(value).strip
              else
                home[key] = sub.nest(value)
              end

            end
          end
          
          if home.save
            home_ids << home.id
            pp "A home has been saved (total: #{home_ids.length}), ##{home.id} changes: ", home.changed_attributes
            
            if home.id_was.nil?
              total_creates += 1
            else
              total_updates += 1
            end
            
            # refresh more home
            more_home_ids = []
            more_homes.each do |mh|
              
              mh[:name] = mh[:name].gsub("#{home.title} - ", "").gsub("#{home.title} ", "")
              
              more_home = Smartrent::MoreHome.where(:home_id => home.id, :name => mh[:name]).first
              
              if more_home
                more_home.update_attributes!(mh)
              else
                more_home = home.more_homes.create(mh)
              end
              
              # create floor plans images
              fp_image_ids = []
              
              mh[:fp_images].each_with_index do |img_url, k|
                fpi = Smartrent::FloorPlanImage.where(:more_home_id => more_home.id, :image_file_name => File.basename(img_url)).first
                
                begin
                  if fpi
                    fpi.update_attributes!(:image => img_url)
                  else
                    fpi = more_home.floor_plan_images.create(:image => img_url)
                  end
                rescue Exception => e
                  pp "saving more home floor plan images..."
                  pp e.message
                  pp e.backtrace.inspect
                end
                
                fp_image_ids << fpi.id
              end
              
              # hide floor plan image which not exist in the xml file
              pp "hide floor plan images not IN: #{fp_image_ids}"
              fp_image_ids.compact!
              Smartrent::FloorPlanImage.unscoped.where("id IN (?)", fp_image_ids).update_all(:is_visible => 1)
              Smartrent::FloorPlanImage.unscoped.where("more_home_id = ? AND id NOT IN (?)", more_home.id, fp_image_ids).update_all(:is_visible => 0)
              
              more_home_ids << more_home.id
            end
            
            # hide more home which not exist in the xml file
            pp "hide more home not IN: #{more_home_ids}"
            more_home_ids.compact!
            Smartrent::MoreHome.unscoped.where("id IN (?)", more_home_ids).update_all(:is_visible => 1)
            Smartrent::MoreHome.unscoped.where("home_id = ? AND id NOT IN (?)", home.id, more_home_ids).update_all(:is_visible => 0)
            
          elsif !home.errors.empty?
            pp "error: ##{home.id}", home.errors.full_messages.join(", ")
          end
          
        end
        
      end
      
      # hide home which not exist in the xml file
      if !home_ids.empty?
        pp "found: #{home_ids.length} smartrent home"
        Smartrent::Home.unscoped.where("id IN (?)", home_ids).update_all(:is_visible => 1)
        Smartrent::Home.unscoped.where("id NOT IN (?)", home_ids).update_all(:is_visible => 0)
      end
      
      Notifier.system_message("[SmartRent] DailyHomeXmlImporter - SUCCESS", 
        "Executed at #{Time.now}, total_creates: #{total_creates}, total_updates: #{total_updates}", Notifier::DEV_ADDRESS).deliver_now
      
      pp "total_creates: #{total_creates}, total_updates: #{total_updates}"
      
    end #/ perform
  end
  
end
