class CreateTvLists < ActiveRecord::Migration[5.1]
  def change
    create_table :tv_lists do |t|
      t.text    :name, :null => false
      t.references :status, foreign_key: true
      t.timestamps null: false
    end
  end
end
