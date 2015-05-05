class AddFieldsToResident < ActiveRecord::Migration
  def change
    add_column :smartrent_residents, :confirmation_token, :string
    add_column :smartrent_residents, :confirmed_at, :datetime
    add_column :smartrent_residents, :confirmation_sent_at, :datetime
    add_column :smartrent_residents, :failed_attempts, :integer, :default => 0, :null => false
    add_column :smartrent_residents, :unlock_token, :string
    add_column :smartrent_residents, :locked_at, :datetime

    add_column :smartrent_residents, :name, :string
    add_column :smartrent_residents, :home_phone, :string
    add_column :smartrent_residents, :work_phone, :string
    add_column :smartrent_residents, :cell_phone, :string
    add_column :smartrent_residents, :company, :string
    add_column :smartrent_residents, :house_hold_size, :integer
    add_column :smartrent_residents, :pets_count, :integer
    add_column :smartrent_residents, :contract_signing_date, :datetime
    add_column :smartrent_residents, :apartment_id, :integer
    add_column :smartrent_residents, :type_, :integer
    add_column :smartrent_residents, :status, :integer
    add_column :smartrent_residents, :current_community, :string
    add_column :smartrent_residents, :move_in_date, :datetime
    add_column :smartrent_residents, :move_out_date, :datetime
    add_column :smartrent_residents, :address, :string
    add_column :smartrent_residents, :city, :string
    add_column :smartrent_residents, :state, :string
    add_column :smartrent_residents, :zip, :string
    #add_column :smartrent_residents, :monthly_awards_amount, :float, :default => 0.0
    #add_column :smartrent_residents, :months_earned, :float, :default => 0.0
    #add_column :smartrent_residents, :total_earned, :float, :default => 0.0
    #add_column :smartrent_residents, :sign_up_bonus, :float, :default => 0.0
    add_column :smartrent_residents, :active, :boolean, :default => true

  end
end
