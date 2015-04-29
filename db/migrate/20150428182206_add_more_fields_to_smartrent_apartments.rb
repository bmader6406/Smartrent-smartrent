class AddMoreFieldsToSmartrentApartments < ActiveRecord::Migration
  def change
    add_column :smartrent_apartments, :one_bedroom, :boolean, :default => false
    add_column :smartrent_apartments, :two_bedroom, :boolean, :default => false
    add_column :smartrent_apartments, :three_bedroom, :boolean, :default => false
    add_column :smartrent_apartments, :four_bedroom, :boolean, :default => false
    add_column :smartrent_apartments, :studio, :boolean, :default => false
  end
end
