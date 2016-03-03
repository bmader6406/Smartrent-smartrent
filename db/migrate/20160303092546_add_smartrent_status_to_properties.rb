class AddSmartrentStatusToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :smartrent_status, :string
    
    Property.all.each do |prop|
      prop.smartrent_status = prop.status
      prop.save
    end
    
  end
end
