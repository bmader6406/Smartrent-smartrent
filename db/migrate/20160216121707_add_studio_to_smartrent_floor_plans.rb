class AddStudioToSmartrentFloorPlans < ActiveRecord::Migration
  def change
    add_column :smartrent_floor_plans, :studio, :boolean, :default => false
    change_column :smartrent_floor_plans, :penthouse,  :boolean, :default => false
  end
end
