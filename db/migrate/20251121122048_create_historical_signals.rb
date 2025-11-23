class CreateHistoricalSignals < ActiveRecord::Migration[8.0]
  def change
    create_table :historical_signals do |t|
      t.references :atom, null: false, foreign_key: true
      t.decimal :signal_value, precision: 20, scale: 8, default: 0.0
      t.decimal :share_price, precision: 20, scale: 8, default: 0.0
      t.datetime :recorded_at, null: false

      t.timestamps
    end
    
    add_index :historical_signals, [:atom_id, :recorded_at]
    add_index :historical_signals, :recorded_at
  end
end
