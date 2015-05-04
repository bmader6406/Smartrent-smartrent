class RemoveFieldsFromResidents < ActiveRecord::Migration
  def up
    remove_column :smartrent_residents, :first_name
    remove_column :smartrent_residents, :last_name
  end

  def down
    add_column :smartrent_residents, :first_name, :string
    add_column :smartrent_residents, :last_name, :string
  end
end
