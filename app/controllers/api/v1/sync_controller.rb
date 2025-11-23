class Api::V1::SyncController < ApplicationController
  # POST /api/v1/sync
  # Déclenche une synchronisation manuelle des atoms depuis la blockchain Intuition
  # Params:
  #   - mode: "new" (défaut) = nouveaux atoms uniquement, "update" = mise à jour, "full" = tout
  #   - limit: nombre max d'atoms à synchroniser (défaut: 500)
  def create
    begin
      mode = params[:mode] || 'new'  # 'new', 'update', 'full'
      limit = params[:limit]&.to_i || 500
      
      current_count = Atom.count
      total_on_network = 164907  # Pourrait être récupéré dynamiquement
      
      case mode
      when 'new'
        # Synchroniser UNIQUEMENT les nouveaux atoms (incrémental)
        Rails.logger.info "🔄 Sync incrémentale: #{current_count} → #{current_count + limit}"
        
        service = BatchSynchronizationService.new
        stats = service.sync_all_atoms(
          start_offset: current_count,
          max_atoms: current_count + limit
        )
        
      when 'update'
        # Mettre à jour les atoms existants (refresh données)
        Rails.logger.info "🔄 Mise à jour des #{[limit, current_count].min} premiers atoms"
        
        service = AtomSynchronizationService.new
        stats = service.sync_atoms(limit: [limit, current_count].min)
        
      when 'full'
        # Tout resynchroniser (déconseillé en production)
        Rails.logger.info "🔄 Synchronisation complète (limite: #{limit})"
        
        service = AtomSynchronizationService.new
        stats = service.sync_atoms(limit: limit)
        
      else
        raise ArgumentError, "Mode invalide: #{mode}. Utilisez 'new', 'update' ou 'full'"
      end
      
      new_count = Atom.count
      added = new_count - current_count
      
      render json: {
        success: true,
        message: "Synchronisation réussie (mode: #{mode})",
        mode: mode,
        network: intuition_config[:network],
        chain_id: active_network_config[:chain_id],
        stats: {
          fetched: stats[:total_fetched] || stats[:fetched],
          created: stats[:total_created] || stats[:created],
          updated: stats[:total_updated] || stats[:updated],
          errors: stats[:total_errors] || stats[:errors],
          added: added
        },
        atoms: {
          before: current_count,
          after: new_count,
          total_on_network: total_on_network,
          coverage_percent: ((new_count.to_f / total_on_network) * 100).round(2)
        }
      }, status: :ok
    rescue StandardError => e
      Rails.logger.error "❌ Erreur sync: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
      
      render json: {
        success: false,
        error: 'Échec de la synchronisation',
        details: e.message
      }, status: :internal_server_error
    end
  end
  
  # GET /api/v1/sync/status
  # Retourne le status de la synchronisation et du réseau
  def status
    last_atom = Atom.order(created_at: :desc).first
    
    render json: {
      network: {
        name: active_network_config[:name],
        chain_id: active_network_config[:chain_id],
        graphql_url: active_network_config[:graphql_url],
        explorer: active_network_config[:explorer]
      },
      database: {
        total_atoms: Atom.count,
        total_historical_signals: HistoricalSignal.count,
        last_sync: last_atom&.created_at
      }
    }
  end
end

