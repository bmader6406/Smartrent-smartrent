class AddPostalCodeToSmartrentProperties < ActiveRecord::Migration
  def change
    add_column :smartrent_properties, :postal_code, :string
  end
end
