class UpdateAtomsForBlockchainData < ActiveRecord::Migration[8.0]
  def change
    # Ajout des champs issus de la blockchain Intuition
    add_column :atoms, :image, :string
    add_column :atoms, :type, :string
    add_column :atoms, :creator_id, :string
    add_column :atoms, :wallet_id, :string
    add_column :atoms, :block_number, :bigint
    add_column :atoms, :emoji, :string
    add_column :atoms, :data, :jsonb
    
    # Métriques financières
    add_column :atoms, :total_shares, :decimal, precision: 30, scale: 18, default: 0.0
    add_column :atoms, :deposits_count, :integer, default: 0
    add_column :atoms, :positions_count, :integer, default: 0
    
    # Calculs de croissance (Phase 2)
    add_column :atoms, :growth_24h_percent, :decimal, precision: 10, scale: 4, default: 0.0
    add_column :atoms, :growth_7d_percent, :decimal, precision: 10, scale: 4, default: 0.0
    
    # Prix de référence pour calculs de croissance
    add_column :atoms, :first_price_24h, :decimal, precision: 30, scale: 18
    add_column :atoms, :first_price_7d, :decimal, precision: 30, scale: 18
    
    # Index pour performances
    add_index :atoms, :type
    add_index :atoms, :creator_id
    add_index :atoms, :block_number
    add_index :atoms, :growth_24h_percent
    add_index :atoms, :growth_7d_percent
  end
end
