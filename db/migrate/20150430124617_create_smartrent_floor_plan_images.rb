class CreateSmartrentFloorPlanImages < ActiveRecord::Migration
  def change
    create_table :smartrent_floor_plan_images do |t|
      t.attachment :image
      t.string :caption
      t.integer :home_id

      t.timestamps
    end
  end
end
