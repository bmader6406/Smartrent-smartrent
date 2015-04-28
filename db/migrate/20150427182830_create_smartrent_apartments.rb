class CreateSmartrentApartments < ActiveRecord::Migration
  def change
    create_table :smartrent_apartments do |t|
      t.string :title
      t.string :phone_number
      t.string :detail_url
      t.string :short_description
      t.string :state
      t.string :county
      t.string :city
      t.string :address
      t.float :lat, :default => 0.0
      t.float :lng, :default => 0.0
      t.float :one_bedroom_price, :default => 0.0
      t.float :two_bedroom_price, :default => 0.0
      t.float :three_bedroom_price, :default => 0.0
      t.float :four_bedroom_price, :default => 0.0
      t.float :studio_price, :default => 0.0
      t.float :pent_house_price, :default => 0.0
      t.boolean :special_promotion, :default => false

      t.timestamps
    end
  end
end
