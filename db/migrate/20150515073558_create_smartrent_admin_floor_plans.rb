class CreateSmartrentAdminFloorPlans < ActiveRecord::Migration
  def change
    create_table :smartrent_floor_plans do |t|
      t.integer :property_id
      t.integer :origin_id
      t.string :name
      t.string :url
      t.float :sq_feet_max
      t.float :sq_feet_min
      t.integer :beds
      t.integer :baths
      t.integer :rent_min
      t.integer :rent_max
      t.boolean :penthouse

      t.timestamps
    end
  end
end
