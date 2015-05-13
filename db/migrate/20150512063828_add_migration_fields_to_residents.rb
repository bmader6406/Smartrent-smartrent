class AddMigrationFieldsToResidents < ActiveRecord::Migration
  def change
    add_column :smartrent_residents, :origin_id, :integer, :limit => 8
    add_column :smartrent_residents, :property_id, :integer, :limit => 8
  end
end
