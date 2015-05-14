class AddNewFieldsToProperty < ActiveRecord::Migration
  def change
    add_column :smartrent_properties, :origin_id, :integer
    add_column :smartrent_properties, :bozzuto_url, :string
    add_column :smartrent_properties, :email, :string
    add_column :smartrent_properties, :promotion_title, :string
    add_column :smartrent_properties, :promotion_subtitle, :string
    add_column :smartrent_properties, :promotion_url, :string
    add_column :smartrent_properties, :promotion_expiration_date, :date
    add_column :smartrent_properties, :zip, :string
    add_column :smartrent_properties, :description, :text
  end
end
