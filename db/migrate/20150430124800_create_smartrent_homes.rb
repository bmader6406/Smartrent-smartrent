class CreateSmartrentHomes < ActiveRecord::Migration
  def change
    create_table :smartrent_homes do |t|
      t.string :name
      t.integer :beds
      t.float :baths
      t.float :sq_ft
      t.boolean :featured
      t.integer :property_id

      t.timestamps
    end
  end
end
