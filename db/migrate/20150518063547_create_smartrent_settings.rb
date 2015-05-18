class CreateSmartrentSettings < ActiveRecord::Migration
  def change
    create_table :smartrent_settings do |t|
      t.string :key
      t.string :value

      t.timestamps
    end
  end
end
