class ChangeColumnTypeForResidents < ActiveRecord::Migration
  def up
    change_column :smartrent_residents, :move_in_date, :date
  end

  def down
    change_column :smartrent_residents, :move_in_date, :datetime
  end
end
