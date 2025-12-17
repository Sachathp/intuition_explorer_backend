class Api::V1::PositionsController < ApplicationController
  # GET /api/v1/positions?address=0x...
  # Retourne les positions (atoms + triples) d'un utilisateur
  def index
    address = params[:address]
    limit = params[:limit]&.to_i || 50
    offset = params[:offset]&.to_i || 0
    
    if address.blank?
      render json: { 
        error: 'Adresse wallet requise',
        message: 'Veuillez fournir un paramètre "address"'
      }, status: :bad_request
      return
    end
    
    # NE PAS normaliser l'adresse - GraphQL Intuition est sensible à la casse (checksummed addresses)
    # On utilise l'adresse telle quelle depuis le wallet
    
    begin
      # Récupérer les positions depuis l'API Intuition via le client GraphQL
      client = IntuitionClientService.new
      positions_data = client.fetch_positions_for_account(
        address, 
        limit: limit, 
        offset: offset
      )
      
      # Enrichir avec les données locales si disponibles
      enriched_positions = enrich_positions(positions_data)
      
      render json: {
        address: address,
        network: intuition_config[:network],
        chain_id: active_network_config[:chain_id],
        positions: enriched_positions,
        count: enriched_positions.count,
        limit: limit,
        offset: offset
      }
      
    rescue StandardError => e
      Rails.logger.error "❌ Erreur récupération positions pour #{address}: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      
      render json: {
        error: 'Erreur lors de la récupération des positions',
        details: e.message
      }, status: :internal_server_error
    end
  end
  
  private
  
  # Enrichit les positions avec les données locales (share_price, growth, etc.)
  def enrich_positions(positions_data)
    positions_data.map do |position|
      # Chercher l'atom local pour enrichir avec les données de croissance
      if position[:entity_type] == 'atom'
        local_atom = Atom.find_by(did: position[:term_id])
        
        if local_atom
          # Utiliser les données locales (plus complètes et optimisées)
          position.merge(
            current_share_price: local_atom.share_price,
            growth_24h_percent: local_atom.growth_24h_percent,
            growth_7d_percent: local_atom.growth_7d_percent,
            market_cap: local_atom.market_cap,
            image: local_atom.image || position[:image],
            description: local_atom.description || position[:label]
          )
        else
          # Fallback sur les données GraphQL brutes
          position
        end
      else
        # Pour les triples, utiliser les données GraphQL directement
        position
      end
    end
  end
end
