class AddPositionsSharesToAtoms < ActiveRecord::Migration[8.0]
  def change
    add_column :atoms, :positions_shares, :decimal, precision: 20, scale: 8, default: 0.0
  end
end
