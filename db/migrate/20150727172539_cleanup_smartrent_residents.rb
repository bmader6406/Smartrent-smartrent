class CleanupSmartrentResidents < ActiveRecord::Migration
  def change
    remove_column :smartrent_residents, :name
    remove_column :smartrent_residents, :home_phone
    remove_column :smartrent_residents, :work_phone
    remove_column :smartrent_residents, :cell_phone
    remove_column :smartrent_residents, :company
    remove_column :smartrent_residents, :contract_signing_date
    remove_column :smartrent_residents, :type_
    remove_column :smartrent_residents, :status
    remove_column :smartrent_residents, :address
    remove_column :smartrent_residents, :city
    remove_column :smartrent_residents, :state
    remove_column :smartrent_residents, :zip
    remove_column :smartrent_residents, :current_community
    remove_column :smartrent_residents, :country
    remove_column :smartrent_residents, :origin_id
    remove_column :smartrent_residents, :unit_id
  end
end
