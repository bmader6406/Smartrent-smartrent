class AddSubtitleToSmartrentHomes < ActiveRecord::Migration
  def change
    add_column :smartrent_homes, :subtitle, :string
  end
end
