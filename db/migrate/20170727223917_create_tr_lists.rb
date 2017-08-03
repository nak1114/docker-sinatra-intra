class CreateTrLists < ActiveRecord::Migration[5.1]
  def change
    create_table :tr_lists do |t|
      t.string  :url, :null => false
      t.text    :name, :null => false
      t.references :status, foreign_key: true
      t.text    :rename
      t.timestamps null: false
      
      t.index :url, unique: true
      
    end
  end
end
