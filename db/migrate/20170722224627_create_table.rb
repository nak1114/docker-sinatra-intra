class CreateTable < ActiveRecord::Migration[5.1]
  def change
    create_table :statuses do |t|
      t.string :short, :null => false
      t.string :name, :null => false

      t.index :name, unique: true
    end
    create_table :products do |t|
      t.string  :url, :null => false
      t.text    :name, :null => false
      t.references :status, foreign_key: true
      t.text    :rename
      t.timestamps null: false
      
      t.index :url, unique: true
      
    end
  end
end
