class AddProfileFieldsToSmartrentUsers < ActiveRecord::Migration
  def change
    add_column :smartrent_users, :name, :string
    add_column :smartrent_users, :move_in_date, :datetime
    add_column :smartrent_users, :address, :string
    add_column :smartrent_users, :city, :string
    add_column :smartrent_users, :state, :string
    add_column :smartrent_users, :zip, :string
    add_column :smartrent_users, :current_community, :string
    add_column :smartrent_users, :monthly_awards_amount, :float, :default => 0.0
    add_column :smartrent_users, :months_earned, :float, :default => 0.0
    add_column :smartrent_users, :total_earned, :float, :default => 0.0
    add_column :smartrent_users, :sign_up_bonus, :float, :default => 0.0
  end
end
