class CreateSmartrentArticles < ActiveRecord::Migration
  def change
    create_table :smartrent_articles do |t|
      t.string :title
      t.text :text

      t.timestamps
    end
  end
end
