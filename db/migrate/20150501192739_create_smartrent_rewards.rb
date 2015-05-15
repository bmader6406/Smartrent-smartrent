class CreateSmartrentRewards < ActiveRecord::Migration
  def change
    create_table :smartrent_rewards do |t|
      t.integer :resident_id
      t.integer :type_
      t.integer :property_id
      t.datetime :period_start
      t.datetime :period_end
      t.float :amount
      t.string :rules_applied

      t.timestamps
    end
  end
end