class AddIsVisibleToSmartrentHomes < ActiveRecord::Migration
  def change
    add_column :smartrent_homes, :updated_by, :string
    add_column :smartrent_homes, :is_visible, :boolean, :default => true
    
    add_column :smartrent_more_homes, :is_visible, :boolean, :default => true
    add_column :smartrent_floor_plan_images, :is_visible, :boolean, :default => true
  end
end
