class AddCurrentUnitIdToSmartrentResidents < ActiveRecord::Migration
  def change
    add_column :smartrent_residents, :current_unit_id, :integer
  end
end
