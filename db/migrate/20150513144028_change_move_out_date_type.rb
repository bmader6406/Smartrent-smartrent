class ChangeMoveOutDateType < ActiveRecord::Migration
  def up
    change_column :smartrent_residents, :move_out_date, :date
  end

  def down
    change_column :smartrent_residents, :move_out_date, :datetime
  end
end
