class AddHomeIdToSmartrentProperties < ActiveRecord::Migration
  def change
    add_column :smartrent_properties, :home_id, :integer
  end
end
