namespace :atoms do
  desc "Resynchroniser tous les atoms depuis l'API Intuition (par lots)"
  task resync_all: :environment do
    puts "╔═══════════════════════════════════════════════════════════╗"
    puts "║    RESYNCHRONISATION COMPLÈTE - TOUS LES ATOMS            ║"
    puts "╚═══════════════════════════════════════════════════════════╝"
    puts ""
    
    service = AtomSynchronizationService.new
    
    # On va récupérer les atoms par lots de 100 depuis l'API
    # L'API GraphQL retourne les atoms les plus récents en premier
    offset = 0
    batch_size = 100
    total_synced = 0
    
    puts "🔄 Stratégie: Synchroniser par lots de #{batch_size} depuis l'API"
    puts "   Cela mettra à jour les atoms existants et en créera de nouveaux"
    puts ""
    
    loop do
      puts "📦 Lot #{offset/batch_size + 1} (offset: #{offset})..."
      
      begin
        stats = service.sync_atoms(limit: batch_size, offset: offset)
        
        if stats[:fetched] == 0
          puts "   ℹ️  Aucun atom récupéré, fin de la synchronisation"
          break
        end
        
        total_synced += stats[:fetched]
        puts "   ✅ #{stats[:fetched]} atoms récupérés"
        puts "      Créés: #{stats[:created]}, Mis à jour: #{stats[:updated]}"
        
        offset += batch_size
        
        # Pause pour ne pas surcharger l'API
        sleep 0.5
        
        # Limiter à 1000 atoms pour le moment (10 lots)
        if offset >= 1000
          puts ""
          puts "⚠️  Limite de 1000 atoms atteinte pour ce test"
          puts "   Pour tout synchroniser, augmentez cette limite"
          break
        end
      rescue => e
        puts "   ❌ Erreur: #{e.message}"
        break
      end
    end
    
    puts ""
    puts "╔═══════════════════════════════════════════════════════════╗"
    puts "║                     RÉSUMÉ FINAL                          ║"
    puts "╚═══════════════════════════════════════════════════════════╝"
    puts ""
    puts "  📊 Total atoms synchronisés: #{total_synced}"
    puts "  📊 Atoms en base: #{Atom.count}"
    puts "  ✅ Atoms > 100 TRUST: #{Atom.where('market_cap > 100').count}"
    puts ""
    
    # Top 10
    puts "🏆 Top 10 atoms par market cap:"
    Atom.where('market_cap > 100').order(market_cap: :desc).limit(10).each_with_index do |a, i|
      puts "  #{i+1}. #{a.description[0..45]}... - #{a.market_cap.round(2)} TRUST"
    end
    puts ""
    puts "✅ Synchronisation terminée!"
  end
  
  desc "Synchroniser massivement N atoms (défaut: 500)"
  task :sync_massive, [:count] => :environment do |t, args|
    count = (args[:count] || 500).to_i
    batch_size = 100
    
    puts "🔄 Synchronisation massive de #{count} atoms..."
    puts ""
    
    service = AtomSynchronizationService.new
    offset = 0
    total_synced = 0
    
    while offset < count
      remaining = count - offset
      current_batch = [remaining, batch_size].min
      
      print "📦 Lot #{offset/batch_size + 1} (#{current_batch} atoms)... "
      
      stats = service.sync_atoms(limit: current_batch, offset: offset)
      
      if stats[:fetched] == 0
        puts "Terminé (plus d'atoms)"
        break
      end
      
      total_synced += stats[:fetched]
      puts "✅ #{stats[:fetched]} récupérés"
      
      offset += current_batch
      sleep 0.3
    end
    
    puts ""
    puts "✅ Synchronisation terminée!"
    puts "   Total synchronisé: #{total_synced}"
    puts "   Atoms > 100 TRUST: #{Atom.where('market_cap > 100').count}"
  end
end



