namespace :atoms do
  desc "Mettre à jour tous les atoms avec les données market_cap de l'API Intuition"
  task update_market_cap: :environment do
    puts "╔═══════════════════════════════════════════════════════════╗"
    puts "║     MISE À JOUR MARKET CAP - TOUS LES ATOMS              ║"
    puts "╚═══════════════════════════════════════════════════════════╝"
    puts ""
    
    service = AtomSynchronizationService.new
    total_atoms = Atom.count
    updated = 0
    failed = 0
    skipped = 0
    
    puts "📊 Total atoms en base: #{total_atoms}"
    puts "🔄 Début de la synchronisation..."
    puts ""
    
    # Traiter par lots de 50
    Atom.find_in_batches(batch_size: 50) do |batch|
      batch.each do |atom|
        begin
          # Synchroniser cet atom depuis l'API
          synced_atom = service.sync_atom(atom.did)
          
          if synced_atom
            updated += 1
            print "." if updated % 50 == 0
          else
            skipped += 1
            print "s" if skipped % 50 == 0
          end
        rescue => e
          failed += 1
          Rails.logger.error "Erreur pour atom #{atom.did}: #{e.message}"
          print "x" if failed % 50 == 0
        end
      end
      
      # Afficher progression tous les 50 atoms
      if (updated + failed + skipped) % 50 == 0
        puts ""
        puts "   Traités: #{updated + failed + skipped} / #{total_atoms}"
        puts "   Mis à jour: #{updated}, Échecs: #{failed}, Ignorés: #{skipped}"
      end
    end
    
    puts ""
    puts ""
    puts "╔═══════════════════════════════════════════════════════════╗"
    puts "║                  RÉSUMÉ FINAL                             ║"
    puts "╚═══════════════════════════════════════════════════════════╝"
    puts ""
    puts "  ✅ Atoms mis à jour: #{updated}"
    puts "  ⏭️  Atoms ignorés: #{skipped}"
    puts "  ❌ Échecs: #{failed}"
    puts ""
    puts "  📊 Atoms avec market_cap > 100 TRUST: #{Atom.where('market_cap > 100').count}"
    puts ""
    
    # Top 5
    puts "🏆 Top 5 atoms par market cap:"
    Atom.where('market_cap > 100').order(market_cap: :desc).limit(5).each_with_index do |a, i|
      puts "  #{i+1}. #{a.description[0..50]}"
      puts "     Market Cap: #{a.market_cap.round(2)} TRUST"
    end
    puts ""
    puts "✅ Synchronisation terminée!"
  end
  
  desc "Mise à jour rapide des N premiers atoms (par défaut 100)"
  task :update_top, [:limit] => :environment do |t, args|
    limit = (args[:limit] || 100).to_i
    
    puts "🔄 Synchronisation des #{limit} premiers atoms..."
    puts ""
    
    service = AtomSynchronizationService.new
    stats = service.sync_atoms(limit: limit)
    
    puts ""
    puts "✅ Synchronisation terminée!"
    puts "   Récupérés: #{stats[:fetched]}"
    puts "   Créés: #{stats[:created]}"
    puts "   Mis à jour: #{stats[:updated]}"
    puts ""
    puts "📊 Total atoms avec market_cap > 100 TRUST: #{Atom.where('market_cap > 100').count}"
  end
end

