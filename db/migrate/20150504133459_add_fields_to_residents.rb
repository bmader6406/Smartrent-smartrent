class AddFieldsToResidents < ActiveRecord::Migration
  def change
    add_column :smartrent_residents, :country, :string
  end
end
