class AddTotalAssetsToAtoms < ActiveRecord::Migration[8.0]
  def change
    add_column :atoms, :total_assets, :decimal, precision: 20, scale: 8, default: 0.0
  end
end
