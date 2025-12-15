# Service de synchronisation par batch pour récupérer TOUS les atoms
# Gère la pagination et les limites de l'API GraphQL (250 atoms/requête)

class BatchSynchronizationService
  BATCH_SIZE = 250  # Limite maximum de l'API Hasura
  SLEEP_BETWEEN_BATCHES = 1  # Seconde(s) entre chaque batch pour éviter le rate limiting
  
  attr_reader :stats
  
  def initialize
    @client = IntuitionClientService.new
    @stats = {
      total_atoms_on_network: 0,
      total_fetched: 0,
      total_created: 0,
      total_updated: 0,
      total_errors: 0,
      batches_processed: 0,
      started_at: Time.current,
      estimated_time_remaining: nil
    }
  end
  
  # Synchronise TOUS les atoms du réseau (ou jusqu'à max_atoms si spécifié)
  def sync_all_atoms(max_atoms: nil, start_offset: 0)
    Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Rails.logger.info "🚀 Synchronisation COMPLÈTE des Atoms"
    Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Récupérer le nombre total d'atoms sur le réseau
    @stats[:total_atoms_on_network] = fetch_total_atoms_count
    Rails.logger.info "📊 Total atoms sur le réseau: #{@stats[:total_atoms_on_network]}"
    
    # Déterminer combien d'atoms à synchroniser
    target_count = max_atoms || @stats[:total_atoms_on_network]
    target_count = [target_count, @stats[:total_atoms_on_network]].min
    
    Rails.logger.info "🎯 Objectif: Synchroniser #{target_count} atoms"
    Rails.logger.info "📦 Batch size: #{BATCH_SIZE} atoms/requête"
    
    total_batches = ((target_count - start_offset).to_f / BATCH_SIZE).ceil
    Rails.logger.info "🔄 Nombre de batches: #{total_batches}"
    Rails.logger.info ""
    
    # Synchroniser par batch
    offset = start_offset
    batch_num = 1
    
    while offset < target_count
      remaining = target_count - offset
      current_batch_size = [BATCH_SIZE, remaining].min
      
      Rails.logger.info "━━━ Batch #{batch_num}/#{total_batches} (offset: #{offset}) ━━━"
      
      begin
        # Récupérer et synchroniser le batch
        batch_stats = sync_batch(offset, current_batch_size)
        
        # Mettre à jour les stats globales
        @stats[:total_fetched] += batch_stats[:fetched]
        @stats[:total_created] += batch_stats[:created]
        @stats[:total_updated] += batch_stats[:updated]
        @stats[:total_errors] += batch_stats[:errors]
        @stats[:batches_processed] += 1
        
        # Afficher la progression
        progress_percent = ((offset + current_batch_size).to_f / target_count * 100).round(2)
        elapsed = Time.current - @stats[:started_at]
        avg_time_per_batch = elapsed / batch_num
        remaining_batches = total_batches - batch_num
        estimated_remaining = (avg_time_per_batch * remaining_batches).to_i
        
        Rails.logger.info "✅ Batch #{batch_num} terminé: #{batch_stats[:created]} créés, #{batch_stats[:updated]} mis à jour"
        Rails.logger.info "📊 Progression: #{offset + current_batch_size}/#{target_count} (#{progress_percent}%)"
        Rails.logger.info "⏱️  Temps estimé restant: #{format_duration(estimated_remaining)}"
        Rails.logger.info ""
        
        @stats[:estimated_time_remaining] = estimated_remaining
        
      rescue StandardError => e
        Rails.logger.error "❌ Erreur batch #{batch_num}: #{e.message}"
        @stats[:total_errors] += current_batch_size
      end
      
      # Passer au batch suivant
      offset += current_batch_size
      batch_num += 1
      
      # Pause entre les batches pour éviter le rate limiting
      sleep(SLEEP_BETWEEN_BATCHES) if offset < target_count
    end
    
    # Stats finales
    log_final_stats
    
    @stats
  end
  
  # Synchronise un batch spécifique
  def sync_batch(offset, limit)
    atoms_data = @client.fetch_atoms_with_pagination(offset: offset, limit: limit)
    
    return { fetched: 0, created: 0, updated: 0, errors: 0 } if atoms_data.empty?
    
    batch_stats = { fetched: atoms_data.count, created: 0, updated: 0, errors: 0 }
    
    atoms_data.each do |atom_data|
      begin
        atom = Atom.find_or_initialize_by(did: atom_data[:did])
        is_new = atom.new_record?
        
        atom.assign_attributes(
          description: atom_data[:description],
          image: atom_data[:image],
          type: atom_data[:type],
          creator_id: atom_data[:creator],
          wallet_id: atom_data[:wallet],
          block_number: atom_data[:block_number],
          current_signal_value: atom_data[:current_signal_value],
          share_price: atom_data[:share_price],
          total_shares: atom_data[:total_shares],
          deposits_count: atom_data[:deposits_count],
          positions_count: atom_data[:positions_count],
          first_price_24h: atom_data[:first_price_24h],
          first_price_7d: atom_data[:first_price_7d]
        )
        
        # Calculer la croissance
        calculate_growth(atom)
        
        if atom.save
          is_new ? batch_stats[:created] += 1 : batch_stats[:updated] += 1
          
          # Enregistrer signal historique
          record_historical_signal(atom)
        else
          batch_stats[:errors] += 1
        end
        
      rescue StandardError => e
        batch_stats[:errors] += 1
        Rails.logger.debug "  ⚠️  Erreur atom #{atom_data[:did][0..20]}: #{e.message}"
      end
    end
    
    batch_stats
  end
  
  # Reprendre une synchronisation interrompue
  def resume_sync
    current_count = Atom.count
    Rails.logger.info "📦 Atoms actuels en BDD: #{current_count}"
    Rails.logger.info "🔄 Reprise de la synchronisation..."
    
    sync_all_atoms(start_offset: current_count)
  end
  
  private
  
  def fetch_total_atoms_count
    @client.fetch_network_stats[:total_atoms] || 0
  end
  
  def calculate_growth(atom)
    if atom.first_price_24h.present? && atom.first_price_24h > 0
      atom.growth_24h_percent = ((atom.share_price - atom.first_price_24h) / atom.first_price_24h) * 100.0
    end
    
    if atom.first_price_7d.present? && atom.first_price_7d > 0
      atom.growth_7d_percent = ((atom.share_price - atom.first_price_7d) / atom.first_price_7d) * 100.0
    end
  end
  
  def record_historical_signal(atom)
    HistoricalSignal.create!(
      atom: atom,
      signal_value: atom.current_signal_value,
      share_price: atom.share_price,
      recorded_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.debug "  ⚠️  Erreur historique: #{e.message}"
  end
  
  def log_final_stats
    elapsed = Time.current - @stats[:started_at]
    
    Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Rails.logger.info "🎉 SYNCHRONISATION TERMINÉE"
    Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Rails.logger.info "📊 STATISTIQUES FINALES"
    Rails.logger.info "  Atoms sur le réseau: #{@stats[:total_atoms_on_network]}"
    Rails.logger.info "  Atoms récupérés: #{@stats[:total_fetched]}"
    Rails.logger.info "  Atoms créés: #{@stats[:total_created]}"
    Rails.logger.info "  Atoms mis à jour: #{@stats[:total_updated]}"
    Rails.logger.info "  Erreurs: #{@stats[:total_errors]}"
    Rails.logger.info "  Batches traités: #{@stats[:batches_processed]}"
    Rails.logger.info "  Temps total: #{format_duration(elapsed.to_i)}"
    Rails.logger.info "  Vitesse moyenne: #{(@stats[:total_fetched] / elapsed).round(2)} atoms/sec"
    Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Rails.logger.info ""
    Rails.logger.info "📦 Total en BDD: #{Atom.count} atoms"
    Rails.logger.info "📈 Total historical signals: #{HistoricalSignal.count}"
  end
  
  def format_duration(seconds)
    hours = seconds / 3600
    minutes = (seconds % 3600) / 60
    secs = seconds % 60
    
    parts = []
    parts << "#{hours}h" if hours > 0
    parts << "#{minutes}m" if minutes > 0
    parts << "#{secs}s" if secs > 0 || parts.empty?
    
    parts.join(' ')
  end
end

