module Smartrent
  class Property < ::Property
    has_many :property_features, :dependent => :destroy
    has_many :features, :through => :property_features
    has_many :floor_plans, :dependent => :destroy
    has_many :resident_properties
    has_many :residents, :through => :resident_properties
    
    before_create :set_smartrent
    
    def self.STATUS_ACTIVE
      "Active"
    end
    
    def self.STATUS_INACTIVE
      "Inactive"
    end
    
    def self.STATUS_CURRENT
      "Current"
    end

    def self.statuses
      {
        "Active" => self.STATUS_ACTIVE,
        "Inactive" => self.STATUS_INACTIVE,
        "Current" => self.STATUS_CURRENT
      }
    end
    
    def self.custom_ransack(q)
      if q
        q.delete_if {|key, value|
          [ "maximum_price", "minimum_price", 
            "where_one_bed", "where_two_bed", "where_three_more_bed",
            "where_penthouse", "where_studio", "matches_all_features"].include?(key)
        }
      end
      super q
    end
    
    def self.filter_from_result(result, properties)
      property_ids = properties.collect{|p| p.id }
      result.collect{|p| p if property_ids.include?(p.id) }.compact
    end

    def self.custom_filters(q_params, properties)
      properties = properties.where(:is_visible => true)
      if q_params
        properties = self.matches_all_features(properties, q_params[:matches_all_features]) if q_params[:matches_all_features]
        properties = self.where_bed(properties, 1) if q_params[:where_one_bed]
        properties = self.where_bed(properties, 2) if q_params[:where_two_bed]
        properties = self.where_bed_more_than_eq(properties, 3) if q_params[:where_three_more_bed]
        properties = self.where_penthouse(properties) if q_params[:where_penthouse]
        properties = self.where_studio(properties) if q_params[:where_studio]
        properties = self.where_price(properties, q_params[:price]) if q_params[:price]
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
        #.where(:floor_plans => {:beds => bed_count})
      result = Property.joins(:floor_plans)
        .where("smartrent_floor_plans.beds = ? and (smartrent_floor_plans.rent_min > 0 or smartrent_floor_plans.rent_max > 0)", bed_count)
        .group("properties.id")
      self.filter_from_result result, properties
    end
    
    def self.where_bed_more_than_eq(properties,bed_count)
      result = Property.joins(:floor_plans)
        .where("smartrent_floor_plans.beds >= ? and (smartrent_floor_plans.rent_min > 0 or smartrent_floor_plans.rent_max > 0)", bed_count)
        .group("properties.id")
      self.filter_from_result result, properties
    end
    
    def self.where_penthouse(properties)
      result = Property.joins(:floor_plans)
        .where(:floor_plans => {:penthouse => true})
        .group("properties.id")
      self.filter_from_result result, properties
    end
    
    def self.where_studio(properties)
      result = Property.joins(:floor_plans)
        .where(:floor_plans => {:studio => true})
        .group("properties.id")
      self.filter_from_result result, properties
    end
    
    def self.where_price(properties, price)
      prices = price.split(",")

      return properties if prices.length != 2
      minimum_price = prices[0].to_i
      maximum_price = prices[1].to_i
      if maximum_price > 0 and minimum_price > 0
        result = Property.joins(:floor_plans)
          .where("smartrent_floor_plans.rent_min >= ?", minimum_price)
          .where("smartrent_floor_plans.rent_max <= ?", maximum_price)
          .group("properties.id")
      elsif minimum_price > 0
        result = Property.joins(:floor_plans)
          .where("smartrent_floor_plans.rent_min >= ?", minimum_price)
          .group("properties.id")
      elsif maximum_price > 0
        result = Property.joins(:floor_plans)
          .where("smartrent_floor_plans.rent_max <= ?", maximum_price)
          .group("properties.id")
      end

      self.filter_from_result result, properties
    end
    
    def self.get_price(q)
      q[:minimum_price] = q[:minimum_price].to_i
      q[:maximum_price] = q[:maximum_price].to_i
      price = "#{q[:minimum_price]},#{q[:maximum_price]}"
      q.delete(:minimum_price)
      q.delete(:maximum_price)
      price
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

    def self.to_csv
      CSV.generate do |csv|
        column_names = ["name", "city", "state"]
        csv << column_names
        where(:is_smartrent => true).each do |property|
          csv << property.attributes.values_at(*column_names)
        end
      end
    end
    
    private
      def set_smartrent
        self.is_smartrent = true
      end

  end
end
