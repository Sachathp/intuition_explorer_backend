class Api::V1::AtomsController < ApplicationController
  before_action :set_atom, only: [:show, :history]
  
  # GET /api/v1/atoms
  # Retourne les atoms triés par market cap décroissant
  # Filtre uniquement les atoms avec market cap > 100 Trust
  def index
    limit = params[:limit]&.to_i || 50
    atoms = Atom.with_minimum_market_cap.top_by_market_cap.limit(limit)
    
    render json: {
      atoms: atoms.as_json(
        only: [
          :id, :did, :description, :current_signal_value, :share_price, 
          :created_at, :updated_at, :image, :type, :creator_id, :wallet_id,
          :block_number, :emoji, :total_shares, :deposits_count, :positions_count,
          :growth_24h_percent, :growth_7d_percent, :market_cap, :total_assets, :positions_shares
        ]
      ),
      count: atoms.count,
      total: Atom.with_minimum_market_cap.count,
      network: intuition_config[:network],
      chain_id: active_network_config[:chain_id]
    }
  end

  # GET /api/v1/atoms/:id
  # Retourne un atom spécifique avec ses détails
  def show
    atom_data = @atom.as_json(
      only: [
        :id, :did, :description, :current_signal_value, :share_price,
        :created_at, :updated_at, :image, :type, :creator_id, :wallet_id,
        :block_number, :emoji, :data, :total_shares, :deposits_count,
        :positions_count, :growth_24h_percent, :growth_7d_percent,
        :first_price_24h, :first_price_7d, :market_cap, :total_assets, :positions_shares
      ]
    )
    
    # Récupérer les triples depuis l'API Intuition si nécessaire
    begin
      client = IntuitionClientService.new
      triples = client.fetch_triples_for_atom(@atom.did)
      atom_data[:triples] = triples if triples.any?
    rescue StandardError => e
      Rails.logger.warn "Impossible de récupérer les triples: #{e.message}"
      atom_data[:triples] = []
    end
    
    render json: { atom: atom_data }
  end
  
  # GET /api/v1/atoms/:id/history
  # Retourne l'historique des valeurs pour les graphiques
  # Supporte: ?days=7 (défaut) ou ?hours=1, ?hours=4
  def history
    if params[:hours]
      hours = params[:hours].to_i
      history_data = @atom.history_for_chart_hours(hours).map do |record|
        {
          timestamp: record.recorded_at.iso8601,
          signal_value: record.signal_value.to_f,
          share_price: record.share_price.to_f
        }
      end
      
      render json: {
        atom_id: @atom.id,
        atom_did: @atom.did,
        period_hours: hours,
        data: history_data,
        count: history_data.count
      }
    else
      days = params[:days]&.to_i || 7
      
      history_data = @atom.history_for_chart(days).map do |record|
        {
          timestamp: record.recorded_at.iso8601,
          signal_value: record.signal_value.to_f,
          share_price: record.share_price.to_f
        }
      end
      
      render json: {
        atom_id: @atom.id,
        atom_did: @atom.did,
        period_days: days,
        data: history_data,
        count: history_data.count
      }
    end
  end
  
  private
  
  def set_atom
    @atom = Atom.find_by(id: params[:id]) || Atom.find_by(did: params[:id])
    
    unless @atom
      render json: { error: 'Atom non trouvé' }, status: :not_found
    end
  end
end
