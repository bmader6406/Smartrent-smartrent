class ChangeHomePageDescToText < ActiveRecord::Migration
  def up
    change_column :smartrent_properties, :home_page_desc, :text
  end
  def down
    change_column :smartrent_properties, :home_page_desc, :string
  end
end
