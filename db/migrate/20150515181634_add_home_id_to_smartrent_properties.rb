class AddHomeIdToSmartrentProperties < ActiveRecord::Migration
  def change
    add_column :smartrent_residents, :home_id, :integer
  end
end
