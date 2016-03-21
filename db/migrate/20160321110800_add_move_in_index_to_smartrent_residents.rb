class AddMoveInIndexToSmartrentResidents < ActiveRecord::Migration
  def change
    add_index "smartrent_residents", ["first_move_in"]
    add_index "smartrent_residents", ["smartrent_status"]
  end
end
