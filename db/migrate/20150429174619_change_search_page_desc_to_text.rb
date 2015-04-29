class ChangeSearchPageDescToText < ActiveRecord::Migration
  def up
    change_column :smartrent_properties, :search_page_sub_title, :text
  end
  def down
    change_column :smartrent_properties, :search_page_sub_title, :string
  end
end
