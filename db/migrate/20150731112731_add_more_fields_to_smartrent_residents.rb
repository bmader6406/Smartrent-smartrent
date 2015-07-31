class AddMoreFieldsToSmartrentResidents < ActiveRecord::Migration
  def change
    add_column :smartrent_residents, :expiry_date, :datetime
    add_column :smartrent_residents, :champion_date, :datetime
    add_column :smartrent_residents, :champion_amount, :float, :default => 0
  end
end
