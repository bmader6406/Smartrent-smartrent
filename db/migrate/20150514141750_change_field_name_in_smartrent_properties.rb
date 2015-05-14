class ChangeFieldNameInSmartrentProperties < ActiveRecord::Migration
  def up
    rename_column :smartrent_properties, :detail_url, :website
    remove_column :smartrent_residents, :apartment_id
    rename_column :smartrent_properties, :lat, :latitude
    rename_column :smartrent_properties, :lng, :longitude
  end

  def down
    rename_column :smartrent_properties, :website, :detail_url
    add_column :smartrent_residents, :apartment_id, :integer
    rename_column :smartrent_properties, :latitude, :lat
    rename_column :smartrent_properties, :longitude, :lng
  end
end
