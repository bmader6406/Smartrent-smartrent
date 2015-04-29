module Smartrent
  class Apartment < ActiveRecord::Base
    has_many :apartment_features, :dependent => :destroy
    has_many :features, :through => :apartment_features
    attr_accessible :address, :city, :county, :detail_url, :four_bedroom_price, :lat, :lng, :one_bedroom_price, :pent_house_price, :phone_number, :short_description, :special_promotion, :state, :studio_price, :three_bedroom_price, :title, :two_bedroom_price
    def self.grouped_by_states(q)
      states = {}
      q.result.each do |apartment|
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
      states
    end
  end
end
