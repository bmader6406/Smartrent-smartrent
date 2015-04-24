class CreateSmartrentProperties < ActiveRecord::Migration
  def change
    create_table :smartrent_properties do |t|
      t.string :title
      t.text :address
      t.string :website
      t.text :description
      t.float :lat
      t.float :lng
      t.attachment :left_image
      t.string :left_image_description

      t.timestamps
    end
  end
end
