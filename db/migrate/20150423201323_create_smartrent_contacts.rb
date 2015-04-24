class CreateSmartrentContacts < ActiveRecord::Migration
  def change
    create_table :smartrent_contacts do |t|
      t.string :name
      t.string :email
      t.text :message

      t.timestamps
    end
  end
end
