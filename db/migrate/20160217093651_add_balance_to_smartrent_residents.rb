class AddBalanceToSmartrentResidents < ActiveRecord::Migration
  def change
    add_column :smartrent_residents, :first_name, :string
    add_column :smartrent_residents, :last_name, :string
    
    add_column :smartrent_residents, :balance, :integer, :default => 0
    add_column :smartrent_residents, :current_property_id, :integer
    
    add_index "smartrent_residents", ["first_name"]
    add_index "smartrent_residents", ["last_name"]
    add_index "smartrent_residents", ["current_property_id"]
    add_index "smartrent_residents", ["balance"]
  end
end
