class RenameImageFields < ActiveRecord::Migration
  def up
    remove_column :smartrent_properties, :left_image_file_name
    remove_column :smartrent_properties, :left_image_content_type
    remove_column :smartrent_properties, :left_image_file_size
    remove_column :smartrent_properties, :left_image_updated_at
    add_attachment :smartrent_properties, :image
    remove_column :smartrent_properties, :left_image_description
    add_column :smartrent_properties, :image_description, :string
    add_column :smartrent_properties, :search_page_description, :text
    remove_column :smartrent_properties, :search_page_sub_title
  end

  def down
    add_attachment :smartrent_properties, :left_image
    remove_column :smartrent_properties, :image_file_name
    remove_column :smartrent_properties, :image_content_type
    remove_column :smartrent_properties, :image_file_size
    remove_column :smartrent_properties, :image_updated_at
    remove_column :smartrent_properties, :image_description
    remove_column :smartrent_properties, :search_page_description
    add_column :smartrent_properties, :left_image_description, :string
    add_column :smartrent_properties, :search_page_sub_title, :string
  end
end
