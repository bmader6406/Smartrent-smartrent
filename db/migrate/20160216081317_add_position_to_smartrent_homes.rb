class AddPositionToSmartrentHomes < ActiveRecord::Migration
  def change
    add_column :smartrent_homes, :position, :integer, :default => 0
    add_column :smartrent_more_homes, :position, :integer, :default => 0
  end
end
