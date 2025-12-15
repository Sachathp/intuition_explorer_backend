class AddMarketCapToAtoms < ActiveRecord::Migration[8.0]
  def change
    add_column :atoms, :market_cap, :decimal, precision: 20, scale: 8, default: 0.0
    add_index :atoms, :market_cap
  end
end
