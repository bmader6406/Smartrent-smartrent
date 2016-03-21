class RenameChampionToBuyer < ActiveRecord::Migration
  def change
    rename_column :smartrent_residents, :champion_amount, :buyer_amount
    rename_column :smartrent_residents, :champion_date, :buyer_date
  end
end
