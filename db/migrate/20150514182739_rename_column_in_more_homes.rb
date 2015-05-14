class RenameColumnInMoreHomes < ActiveRecord::Migration
  def up
    rename_column :smartrent_more_homes, :property_id, :home_id
  end

  def down
    rename_column :smartrent_more_homes, :home_id, :property_id
  end
end
