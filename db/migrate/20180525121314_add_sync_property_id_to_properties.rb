class AddSyncPropertyIdToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :sync_property_id, :string
  end
end
