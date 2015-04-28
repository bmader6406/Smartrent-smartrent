class CreateSmartrentFeatures < ActiveRecord::Migration
  def change
    create_table :smartrent_features do |t|
      t.string :name

      t.timestamps
    end
  end
end
