class AddFieldsToSmartrentUsers < ActiveRecord::Migration
  def change
    add_column :smartrent_users, :confirmation_token, :string
    add_column :smartrent_users, :confirmed_at, :datetime
    add_column :smartrent_users, :confirmation_sent_at, :datetime
    add_column :smartrent_users, :failed_attempts, :integer, :default => 0, :null => false
    add_column :smartrent_users, :unlock_token, :string
    add_column :smartrent_users, :locked_at, :datetime
  end
end
