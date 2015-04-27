class AddFieldsToSmartrentProperty < ActiveRecord::Migration
  def change
    add_column :smartrent_properties, :phone_number, :string
    add_column :smartrent_properties, :video_url, :string
  end
end
