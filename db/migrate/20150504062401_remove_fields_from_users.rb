class RemoveFieldsFromUsers < ActiveRecord::Migration
  def up
    remove_column :smartrent_users, :move_in_date
    remove_column :smartrent_users, :current_community
    remove_column :smartrent_users, :monthly_awards_amount
    remove_column :smartrent_users, :months_earned
    remove_column :smartrent_users, :total_earned
    remove_column :smartrent_users, :sign_up_bonus
  end

  def down
    add_column :smartrent_users, :move_in_date, :datetime
    add_column :smartrent_users, :current_community, :string
    add_column :smartrent_users, :monthly_awards_amount, :float, :default => 0.0
    add_column :smartrent_users, :months_earned, :float, :default => 0.0
    add_column :smartrent_users, :total_earned, :float, :default => 0.0
    add_column :smartrent_users, :sign_up_bonus, :float, :default => 0.0
  end
end
