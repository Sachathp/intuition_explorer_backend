# Service de synchronisation des Atoms depuis la blockchain Intuition
# Basé sur le plan migratedata.md - Étape 2: Processeur de Données (IDP)

class AtomSynchronizationService
  attr_reader :client
  
  def initialize
    @client = IntuitionClientService.new
    @stats = {
      fetched: 0,
      created: 0,
      updated: 0,
      errors: 0
    }
  end
  
  # ═══════════════════════════════════════════════════════════
  # ÉTAPE 2.2: Mise à Jour Atomique et Historique
  # ═══════════════════════════════════════════════════════════
  
  # Synchronise les atoms depuis le réseau
  def sync_atoms(limit: 100)
    Rails.logger.info "🔄 Début de la synchronisation des Atoms (limit: #{limit})..."
    
    # Fetch atoms from network
    network_atoms = @client.fetch_atoms_from_network(limit: limit)
    
    if network_atoms.empty?
      Rails.logger.warn "⚠️  Aucun atom récupéré depuis le réseau"
      return @stats
    end
    
    @stats[:fetched] = network_atoms.count
    Rails.logger.info "📥 #{@stats[:fetched]} atoms récupérés depuis le réseau"
    
    # Process each atom
    network_atoms.each_with_index do |atom_data, index|
      process_atom(atom_data)
      
      # Log progress every 10 atoms
      if (index + 1) % 10 == 0
        Rails.logger.info "  📊 Progress: #{index + 1}/#{network_atoms.count} atoms traités"
      end
    end
    
    # Log final stats
    log_sync_stats
    
    @stats
  end
  
  # Synchronise un seul atom spécifique
  def sync_atom(atom_id)
    Rails.logger.info "🔄 Synchronisation de l'atom #{atom_id}..."
    
    atom_data = @client.fetch_atom_by_id(atom_id)
    
    if atom_data.nil?
      Rails.logger.error "❌ Atom #{atom_id} non trouvé"
      return nil
    end
    
    process_atom(atom_data)
    log_sync_stats
    
    Atom.find_by(did: atom_id)
  end
  
  private
  
  # Traite un atom: création ou mise à jour
  def process_atom(atom_data)
    atom = Atom.find_or_initialize_by(did: atom_data[:did])
    
    is_new = atom.new_record?
    
    begin
      # Update attributes
      atom.assign_attributes(
        description: atom_data[:description],
        image: atom_data[:image],
        type: atom_data[:type],
        creator_id: atom_data[:creator],
        wallet_id: atom_data[:wallet],
        block_number: atom_data[:block_number],
        
        # Financial metrics
        current_signal_value: atom_data[:current_signal_value],
        share_price: atom_data[:share_price],
        total_shares: atom_data[:total_shares],
        
        # Statistics
        deposits_count: atom_data[:deposits_count],
        positions_count: atom_data[:positions_count],
        
        # Growth reference prices
        first_price_24h: atom_data[:first_price_24h],
        first_price_7d: atom_data[:first_price_7d]
      )
      
      # Calculate growth percentages (Phase 2 - Étape 2.3)
      calculate_growth_percentages(atom)
      
      if atom.save
        is_new ? @stats[:created] += 1 : @stats[:updated] += 1
        
        # Record historical signal (Phase 2 - Étape 2.2)
        record_historical_signal(atom)
      else
        @stats[:errors] += 1
        Rails.logger.error "❌ Erreur sauvegarde atom #{atom.did}: #{atom.errors.full_messages.join(', ')}"
      end
      
    rescue StandardError => e
      @stats[:errors] += 1
      Rails.logger.error "❌ Erreur traitement atom #{atom_data[:did]}: #{e.message}"
      Rails.logger.error e.backtrace.first(5).join("\n")
    end
  end
  
  # ═══════════════════════════════════════════════════════════
  # ÉTAPE 2.3: Calcul de Croissance
  # ═══════════════════════════════════════════════════════════
  
  # Calcule les pourcentages de croissance sur 24h et 7 jours
  def calculate_growth_percentages(atom)
    # Calcul croissance 24h
    if atom.first_price_24h.present? && atom.first_price_24h > 0
      atom.growth_24h_percent = calculate_percentage_change(
        atom.first_price_24h, 
        atom.share_price
      )
    end
    
    # Calcul croissance 7 jours
    if atom.first_price_7d.present? && atom.first_price_7d > 0
      atom.growth_7d_percent = calculate_percentage_change(
        atom.first_price_7d, 
        atom.share_price
      )
    end
  end
  
  # Calcule le pourcentage de variation entre deux prix
  def calculate_percentage_change(old_price, new_price)
    return 0.0 if old_price.to_f.zero?
    ((new_price.to_f - old_price.to_f) / old_price.to_f) * 100.0
  end
  
  # ═══════════════════════════════════════════════════════════
  # HISTORICAL SIGNAL RECORDING
  # ═══════════════════════════════════════════════════════════
  
  # Enregistre un point d'historique pour l'atom
  def record_historical_signal(atom)
    HistoricalSignal.create!(
      atom: atom,
      signal_value: atom.current_signal_value,
      share_price: atom.share_price,
      recorded_at: Time.current
    )
  rescue StandardError => e
    Rails.logger.warn "⚠️  Erreur enregistrement historique pour #{atom.did}: #{e.message}"
  end
  
  # ═══════════════════════════════════════════════════════════
  # LOGGING
  # ═══════════════════════════════════════════════════════════
  
  def log_sync_stats
    Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Rails.logger.info "✅ Synchronisation terminée"
    Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    Rails.logger.info "  📥 Récupérés: #{@stats[:fetched]}"
    Rails.logger.info "  ✨ Créés: #{@stats[:created]}"
    Rails.logger.info "  🔄 Mis à jour: #{@stats[:updated]}"
    Rails.logger.info "  ❌ Erreurs: #{@stats[:errors]}"
    Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  end
end


