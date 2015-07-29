# run only one time
class RemoveUnusedTables < ActiveRecord::Migration
  def up
    remove_column :smartrent_resident_properties, :house_hold_size
    remove_column :smartrent_resident_properties, :pets_count
    remove_column :smartrent_resident_properties, :contract_signing_date
  end
  
  def down
    
  end
end
