class AddMoveInToSmartrentResidents < ActiveRecord::Migration
  def change
    add_column :smartrent_residents, :first_move_in, :date
    add_column :smartrent_residents, :email_check, :string, :default => "Ok"
    add_column :smartrent_residents, :subscribed, :boolean, :default => true
  end
end
