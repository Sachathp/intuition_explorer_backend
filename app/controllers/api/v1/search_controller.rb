class Api::V1::SearchController < ApplicationController
  # GET /api/v1/search?query=...
  # Recherche lexicale simple dans les atoms
  # Filtre uniquement les atoms avec market cap > 100 Trust
  def index
    query = params[:query]
    limit = params[:limit]&.to_i || 20
    
    if query.blank?
      render json: { 
        atoms: [], 
        count: 0,
        query: query 
      }
      return
    end
    
    atoms = Atom.with_minimum_market_cap.search(query).limit(limit)
    
    render json: {
      atoms: atoms.as_json(only: [:id, :did, :description, :current_signal_value, :share_price, :market_cap, :total_assets, :positions_shares, :created_at, :updated_at]),
      count: atoms.count,
      query: query
    }
  end
end
