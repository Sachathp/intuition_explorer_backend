class CreateAtoms < ActiveRecord::Migration[8.0]
  def change
    create_table :atoms do |t|
      t.string :did, null: false
      t.text :description
      t.decimal :current_signal_value, precision: 20, scale: 8, default: 0.0
      t.decimal :share_price, precision: 20, scale: 8, default: 0.0

      t.timestamps
    end
    
    add_index :atoms, :did, unique: true
    add_index :atoms, :current_signal_value
    add_index :atoms, :share_price
  end
end
