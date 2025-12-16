class AddHourlyGrowthToAtoms < ActiveRecord::Migration[8.0]
  def change
    # Croissance sur 1 heure et 4 heures
    add_column :atoms, :growth_1h_percent, :decimal, precision: 10, scale: 4, default: 0.0
    add_column :atoms, :growth_4h_percent, :decimal, precision: 10, scale: 4, default: 0.0
    
    # Prix de référence pour les calculs
    add_column :atoms, :first_price_1h, :decimal, precision: 30, scale: 18
    add_column :atoms, :first_price_4h, :decimal, precision: 30, scale: 18
    
    # Index pour performances de tri
    add_index :atoms, :growth_1h_percent
    add_index :atoms, :growth_4h_percent
  end
end
