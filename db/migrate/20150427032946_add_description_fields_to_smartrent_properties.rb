class AddDescriptionFieldsToSmartrentProperties < ActiveRecord::Migration
  def change
    add_column :smartrent_properties, :home_page_desc, :string
    add_column :smartrent_properties, :search_page_sub_title, :string
    add_column :smartrent_properties, :city, :string
    add_column :smartrent_properties, :state, :string
  end
end
