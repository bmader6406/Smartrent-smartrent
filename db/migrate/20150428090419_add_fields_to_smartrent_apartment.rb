class AddFieldsToSmartrentApartment < ActiveRecord::Migration
  def change
    add_column :smartrent_apartments, :image, :attachment
  end
end
