class RenameTableHomesToMoreHome < ActiveRecord::Migration
  def change
    rename_table :smartrent_homes, :smartrent_more_homes
    rename_table :smartrent_properties, :smartrent_homes
    rename_table :smartrent_apartments, :smartrent_properties
    rename_table :smartrent_apartment_features, :smartrent_property_features
  end

end
