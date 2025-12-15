class Api::V1::TrendingController < ApplicationController
  # GET /api/v1/trending
  # Retourne les atoms avec la plus forte croissance (triés par growth_24h_percent ou growth_7d_percent)
  # Filtre uniquement les atoms avec market cap > 100 Trust
  def index
    period = params[:period] || '24h' # 24h ou 7d
    limit = params[:limit]&.to_i || 20
    
    # Utiliser les champs de croissance déjà calculés pour de meilleures performances
    growth_field = period == '7d' ? :growth_7d_percent : :growth_24h_percent
    
    atoms = Atom.with_minimum_market_cap.order(growth_field => :desc).limit(limit)
    
    render json: {
      trending: atoms.as_json(
        only: [
          :id, :did, :description, :current_signal_value, :share_price,
          :created_at, :updated_at, :image, :type, :creator_id, :wallet_id,
          :block_number, :emoji, :total_shares, :deposits_count,
          :positions_count, :growth_24h_percent, :growth_7d_percent, :market_cap, :total_assets, :positions_shares
        ],
        methods: []
      ).map do |atom_data|
        growth = atom_data[growth_field.to_s].to_f
        atom_data.merge(
          growth_percentage: growth.round(2),
          growth_direction: growth > 0 ? 'up' : (growth < 0 ? 'down' : 'stable')
        )
      end,
      period: period,
      count: atoms.count,
      network: intuition_config[:network]
    }
  end
end
