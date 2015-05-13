class RenameFieldsInSmartrentProperties < ActiveRecord::Migration
  def up
    rename_column :smartrent_properties, :lng, :longitude
    rename_column :smartrent_properties, :lat, :latitude
  end

  def down
    rename_column :smartrent_properties, :latitude, :lat
    rename_column :smartrent_properties, :longitude, :lng
  end
end
