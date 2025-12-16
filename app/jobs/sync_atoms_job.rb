# Job pour synchroniser automatiquement les atoms
# Utilisé pour les tâches récurrentes (toutes les 6 heures)
class SyncAtomsJob < ApplicationJob
  queue_as :default

  # Mode de synchronisation:
  # - 'update': Met à jour les atoms existants (market cap, share price, etc.)
  # - 'new': Ajoute uniquement les nouveaux atoms
  # - 'full': Resynchronise tout (déconseillé)
  def perform(mode: 'update', limit: 1000)
    Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Rails.logger.info "🔄 Démarrage SyncAtomsJob (mode: #{mode}, limit: #{limit})"
    Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    current_count = Atom.count
    Rails.logger.info "📊 Atoms actuels en BDD: #{current_count}"
    
    case mode
    when 'update'
      # Mettre à jour les atoms existants pour rafraîchir les données
      Rails.logger.info "🔄 Mode UPDATE: Mise à jour des #{[limit, current_count].min} premiers atoms"
      service = AtomSynchronizationService.new
      stats = service.sync_atoms(limit: [limit, current_count].min)
      
    when 'new'
      # Ajouter uniquement les nouveaux atoms (incrémental)
      Rails.logger.info "🔄 Mode NEW: Ajout des nouveaux atoms (limite: #{limit})"
      service = BatchSynchronizationService.new
      stats = service.sync_all_atoms(
        start_offset: current_count,
        max_atoms: current_count + limit
      )
      
    when 'full'
      # Resynchroniser tout (déconseillé, seulement pour maintenance)
      Rails.logger.warn "⚠️  Mode FULL: Resynchronisation complète"
      service = AtomSynchronizationService.new
      stats = service.sync_atoms(limit: limit)
      
    else
      Rails.logger.error "❌ Mode invalide: #{mode}"
      return
    end
    
    new_count = Atom.count
    
    Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Rails.logger.info "✅ SyncAtomsJob terminé"
    Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Rails.logger.info "📊 STATISTIQUES:"
    Rails.logger.info "  Atoms avant: #{current_count}"
    Rails.logger.info "  Atoms après: #{new_count}"
    Rails.logger.info "  Récupérés: #{stats[:total_fetched] || stats[:fetched]}"
    Rails.logger.info "  Créés: #{stats[:total_created] || stats[:created]}"
    Rails.logger.info "  Mis à jour: #{stats[:total_updated] || stats[:updated]}"
    Rails.logger.info "  Erreurs: #{stats[:total_errors] || stats[:errors]}"
    Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
  rescue StandardError => e
    Rails.logger.error "❌ Erreur SyncAtomsJob: #{e.message}"
    Rails.logger.error e.backtrace.first(10).join("\n")
    raise e  # Re-raise pour que Solid Queue puisse gérer les retries
  end
end

