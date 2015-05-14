class RenameFieldsToMeetNewPropertyRequirements < ActiveRecord::Migration
  def up
    rename_column :smartrent_property_features, :apartment_id, :property_id
  end

  def down
    rename_column :smartrent_property_features, :property_id, :apartment_id
  end
end
