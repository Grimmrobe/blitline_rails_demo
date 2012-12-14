class CreatePaintings < ActiveRecord::Migration
  def change
    create_table :paintings do |t|
      t.string :name
      t.string :img_ori
      t.string :img_large
      t.string :img_thumb

      t.timestamps
    end
  end
end
