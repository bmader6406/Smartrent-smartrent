class AddUrlToProperties < ActiveRecord::Migration
  def change
    add_column :properties, :url, :string
  end
end
