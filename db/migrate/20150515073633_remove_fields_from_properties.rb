class RemoveFieldsFromProperties < ActiveRecord::Migration
  def change
    remove_column :smartrent_properties, :one_bedroom_price
    remove_column :smartrent_properties, :one_bedroom
    remove_column :smartrent_properties, :two_bedroom_price
    remove_column :smartrent_properties, :two_bedroom
    remove_column :smartrent_properties, :three_bedroom
    remove_column :smartrent_properties, :three_bedroom_price
    remove_column :smartrent_properties, :four_bedroom
    remove_column :smartrent_properties, :four_bedroom_price
    remove_column :smartrent_properties, :penthouse
    remove_column :smartrent_properties, :pent_house_price
  end
end
