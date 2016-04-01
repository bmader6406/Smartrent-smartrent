class CreateSmartrentTestAccounts < ActiveRecord::Migration
  def change
    create_table :smartrent_test_accounts do |t|
      t.string :resident_id
      t.string :origin_email
      t.string :new_email
      t.datetime :deleted_at

      t.timestamps null: false
    end
  end
end
