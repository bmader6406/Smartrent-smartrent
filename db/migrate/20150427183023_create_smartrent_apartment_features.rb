class CreateSmartrentApartmentFeatures < ActiveRecord::Migration
  def change
    create_table :smartrent_apartment_features do |t|
      t.integer :feature_id
      t.integer :apartment_id

      t.timestamps
    end
  end
end
