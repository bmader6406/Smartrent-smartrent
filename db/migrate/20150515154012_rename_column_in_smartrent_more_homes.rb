class RenameColumnInSmartrentMoreHomes < ActiveRecord::Migration
  def up
    rename_column :smartrent_floor_plan_images, :home_id, :more_home_id
  end

  def down
    rename_column :smartrent_floor_plan_images, :more_home_id, :home_id
  end
end
