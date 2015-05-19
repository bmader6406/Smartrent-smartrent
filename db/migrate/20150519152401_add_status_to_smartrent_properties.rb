class AddStatusToSmartrentProperties < ActiveRecord::Migration
  def change
    add_column :smartrent_properties, :status, :integer, :default => 1
  end
end
