class AddUnitCodeToSmartrentResidentProperties < ActiveRecord::Migration
  def change
    add_column :smartrent_resident_properties, :unit_code, :string
  end
end
