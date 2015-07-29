class AddIndexesToTables < ActiveRecord::Migration
  def change
    add_index "smartrent_floor_plans", ["property_id"]
    add_index "smartrent_more_homes", ["home_id"]
    
    add_index "smartrent_property_features", ["property_id"]
    add_index "smartrent_property_features", ["feature_id"]
    
    add_index "smartrent_floor_plan_images", ["more_home_id"]
    
    add_index "smartrent_rewards", ["resident_id"]
    add_index "smartrent_rewards", ["property_id"]
  end
end
