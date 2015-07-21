module Smartrent
  class Property < ::Property
    has_many :property_features, :dependent => :destroy
    has_many :features, :through => :property_features
    has_many :floor_plans, :dependent => :destroy
    has_many :resident_properties
    has_many :residents, :through => :resident_properties

    before_save do
      self.state = self.state.downcase if self.state
      self.city = self.city.downcase if self.city
      self.county = self.county.downcase if self.county
    end


    def self.property_ids_from_properties(properties)
      property_ids = []
      properties.each do |property|
        property_ids.push property.id
      end
      property_ids
    end

    def self.filter_from_result(result, properties)
      property_ids = self.property_ids_from_properties(properties)
      properties = []
      result.each do |property|
        if property_ids.include?(property.id)
          properties.push property
        end
      end
      properties
    end

    def self.custom_filters(q_params, properties)
      if q_params.present?
        properties = self.matches_all_features(properties, q_params[:matches_all_features]) if q_params[:matches_all_features].present?
        properties = self.where_bed(properties, 1) if q_params[:where_one_bed].present?
        properties = self.where_bed(properties, 2) if q_params[:where_two_bed].present?
        properties = self.where_bed_more_than_eq(properties, 3) if q_params[:where_three_more_bed].present?
        properties = self.where_penthouse(properties) if q_params[:where_penthouse].present?
        properties = self.where_price(properties, q_params[:price]) if q_params[:where_price].present?
      end
      properties
    end

    def self.matches_all_features(properties, feature_ids)
      result = Property.joins(:property_features)
        .where(:property_features => {:feature_id => feature_ids})
        .group("properties.id")
        .having("count(*) = ?", feature_ids.count)
      self.filter_from_result result, properties
    end

    def self.where_bed(properties, bed_count)
      result = Property.joins(:floor_plans)
        .where(:floor_plans => {:beds => bed_count})
        .group("properties.id")
      self.filter_from_result result, properties
    end
    def self.where_bed_more_than_eq(properties,bed_count)
      result = Property.joins(:floor_plans)
        .where("smartrent_floor_plans.beds >= ?", bed_count)
        .group("properties.id")
      self.filter_from_result result, properties
    end
    def self.where_penthouse(properties)
      result = Property.joins(:floor_plans)
        .where(:floor_plans => {:penthouse => true})
        .group("properties.id")
      self.filter_from_result result, properties
    end
    def self.where_price(price, properties)
      prices = price.split(",")
      puts prices
      puts prices.length
      return properties if prices.length != 2
      minimum_price = prices[0].to_i
      maximum_price = prices[1].to_i
      if maximum_price > 0 and minimum_price > 0
        result = Property.joins(:floor_plans)
          .where("smartrent_floor_plans.rent_min >= ?", minimum_price)
          .where("smartrent_floor_plans.rent_max <= ?", maximum_price)
          .group("smartrent_properties.id")
      elsif minimum_price > 0
        result = Property.joins(:floor_plans)
          .where("smartrent_floor_plans.rent_min >= ?", minimum_price)
          .group("smartrent_properties.id")
      elsif maximum_price > 0
        result = Property.joins(:floor_plans)
          .where("smartrent_floor_plans.rent_max <= ?", maximum_price)
          .group("smartrent_properties.id")
      end
    end

    def self.unique_result(q)
        properties = q.result
        ids = []
        properties.each do |property|
          next if ids.include?(property.id)
          ids.push property.id
        end
        properties
    end
    def self.STATUS_ACTIVE
      "Active"
    end
    def self.STATUS_INACTIVE
      "InActive"
    end
    def self.STATUS_CURRENT
      "Current"
    end

    def self.import(file)
      if file.class.to_s == "ActionDispatch::Http::UploadedFile"
        f = File.open(file.path, "r:bom|utf-8")
      else
        f = File.open(Smartrent::Engine.root.to_path + "/data/properties.csv")
      end
      properties = SmarterCSV.process(f)
      properties.each do |property_hash|
        property_hash[:name] = HTMLEntities.new.decode property_hash[:name]
        property_hash[:description] = HTMLEntities.new.decode property_hash[:description]
        property_hash[:is_smartrent] = true
        create property_hash
      end
    end

    def self.prices(chose_text)
      prices = []
      (0..10000).step(250).each do |price|
        if price == 0
          price_array = [chose_text, price]
        else
          price_array = ['$' + price.to_s, price]
        end
        prices.push price_array
      end
      prices
    end

    def self.keyed_by_name
      properties = {}
      all.each do |property|
        properties[property.name] = property
      end
      properties
    end

    def self.grouped_by_states(properties)
      states = {}
      properties.each do |property|
        state = property.state.downcase if property.nil?
        next if !state.present?
        states[state] ||= {}
        states[state]["cities"] ||= {}
        states[state]["cities"][property.city] ||= 0
        states[state]["cities"][property.city] +=1
        states[state]["counties"] ||= {}
        if property.county.present?
          states[state]["counties"][property.county] ||= 0
          states[state]["counties"][property.county] +=1
        end
        states[state]["properties"] ||= []
        states[state]["properties"].push property
        states[state]["total"] ||= 0
        states[state]["total"] +=1
      end
      states
    end
    def self.get_price(q)
      q[:minimum_price] = q[:minimum_price].to_i
      q[:maximum_price] = q[:maximum_price].to_i
      price = "#{q[:minimum_price]},#{q[:maximum_price]}"
      q.delete(:minimum_price)
      q.delete(:maximum_price)
      price
    end

    def self.custom_ransack(q)
      if q
        q.delete_if {|key, value| key == "studio_true" or key == "maximum_price" or key == "minimum_price" or key == "where_one_bed" or key == "where_two_bed" or key == "where_three_more_bed" or key == "where_penthouse"}
      end
      super q
    end

    def self.prices(chose_text)
      prices = []
      (0..10000).step(250).each do |price|
        if price == 0
          price_array = [chose_text, price]
        else
          price_array = ['$' + price.to_s, price]
        end
        prices.push price_array
      end
      prices
    end

    def one_bedroom
      floor_plans.where(:beds => 1).order(:rent_min)
    end

    def two_bedrooms
      floor_plans.where(:beds => 2).order(:rent_min)
    end

    def three_bedrooms
      floor_plans.where(:beds => 3).order(:rent_min)
    end

    def four_bedrooms
      floor_plans.where(:beds => 4).order(:rent_min)
    end

    def penthouses
      floor_plans.where(:penthouse => true).order(:rent_min)
    end
  end
end
