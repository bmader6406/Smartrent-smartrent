class AddPenthouseToSmartrentApartments < ActiveRecord::Migration
  def change
    add_column :smartrent_apartments, :penthouse, :boolean, :default => false
  end
end
