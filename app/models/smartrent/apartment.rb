module Smartrent
  class Apartment < ActiveRecord::Base
    has_many :apartment_features, :dependent => :destroy
    has_many :features, :through => :apartment_features
    attr_accessible :address, :city, :county, :detail_url, :four_bedroom_price, :lat, :lng, :one_bedroom_price, :pent_house_price, :phone_number, :short_description, :special_promotion, :state, :studio_price, :three_bedroom_price, :title, :two_bedroom_price, :one_bedroom, :two_bedroom, :three_bedroom, :four_bedroom, :studio, :penthouse, :image, :feature_ids
    has_attached_file :image, :styles => {:search_page => "150x150>"}
    validates_attachment_content_type :image, :content_type => /\Aimage\/.*\Z/
    before_save do
      self.state = self.state.downcase
      self.city = self.city.downcase
      self.county = self.county.downcase
    end
    def self.grouped_by_states(q)
      states = {}
      apartments = q.result.uniq#.includes(:features)
      apartments.each do |apartment|
          states[apartment.state] = {} if states[apartment.state].nil?
          states[apartment.state]["cities"] = {}  if states[apartment.state]["cities"].nil?
          states[apartment.state]["cities"][apartment.city] = 0 if states[apartment.state]["cities"][apartment.city].nil?
          states[apartment.state]["cities"][apartment.city] +=1
          states[apartment.state]["counties"] = {}  if states[apartment.state]["counties"].nil?
          states[apartment.state]["counties"][apartment.county] = 0 if states[apartment.state]["counties"][apartment.county].nil?
          states[apartment.state]["counties"][apartment.county] +=1
          states[apartment.state]["apartments"] = []  if states[apartment.state]["apartments"].nil?
          states[apartment.state]["apartments"].push apartment
          states[apartment.state]["total"] = 0  if states[apartment.state]["total"].nil?
          states[apartment.state]["total"] +=1
      end
      puts states
      states
    end
    def self.ransack(q)
      if q
        q.delete_if {|key, value| key == "one_bedroom_true" and value == "0"}
        q.delete_if {|key, value| key == "two_bedroom_true" and value == "0"}
        q.delete_if {|key, value| key == "three_bedroom_true" and value == "0"}
        q.delete_if {|key, value| key == "four_bedroom_true" and value == "0"}
        q.delete_if {|key, value| key == "penthouse_true" and value == "0"}
        q.delete_if {|key, value| key == "studio_true" and value == "0"}
        q.delete_if {|key, value| key == "one_bedroom_price_or_two_bedroom_price_or_three_bedroom_price_or_four_bedroom_price_or_studio_price_or_pent_house_price_gteq" and value == "0"}
        q.delete_if {|key, value| key == "one_bedroom_price_or_two_bedroom_price_or_three_bedroom_price_or_four_bedroom_price_or_studio_price_or_pent_house_price_lteq" and value == "0"}
        #q.delete(:two_bedroom_true) if q[:two_bedroom_true] == "0"
        #q.delete(:three_bedroom_true) if q[:three_bedroom_true] == "0"
        #q.delete(:four_bedroom_true) if q[:four_bedroom_true] == "0"
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
  end
end
