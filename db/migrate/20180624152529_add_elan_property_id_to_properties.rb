class AddElanPropertyIdToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :elan_property_id, :string
  end
end
