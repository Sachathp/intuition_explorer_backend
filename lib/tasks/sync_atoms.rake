namespace :sync do
  desc "Synchroniser TOUS les atoms du mainnet Intuition (164,907)"
  task all: :environment do
    puts "🚀 Démarrage de la synchronisation COMPLÈTE..."
    puts "⚠️  Cela va prendre environ 11 minutes"
    puts ""
    
    service = BatchSynchronizationService.new
    stats = service.sync_all_atoms
    
    puts ""
    puts "✅ Synchronisation terminée !"
    puts "📦 Total en BDD: #{Atom.count} atoms"
  end

  desc "Synchroniser X atoms (ex: rake sync:atoms[10000])"
  task :atoms, [:count] => :environment do |t, args|
    count = args[:count]&.to_i || 1000
    
    puts "🚀 Synchronisation de #{count} atoms..."
    
    service = BatchSynchronizationService.new
    stats = service.sync_all_atoms(max_atoms: count)
    
    puts ""
    puts "✅ Terminé !"
    puts "📦 Total en BDD: #{Atom.count} atoms"
  end

  desc "Reprendre une synchronisation interrompue"
  task resume: :environment do
    current = Atom.count
    puts "📦 Atoms actuels: #{current}"
    puts "🔄 Reprise de la synchronisation..."
    
    service = BatchSynchronizationService.new
    service.resume_sync
  end

  desc "Afficher les statistiques de synchronisation"
  task stats: :environment do
    total_network = 164907
    current = Atom.count
    percent = (current.to_f / total_network * 100).round(2)
    
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts "📊 STATISTIQUES DE SYNCHRONISATION"
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    puts ""
    puts "🌐 Réseau: Intuition Mainnet"
    puts "🔗 Chain ID: 1155"
    puts ""
    puts "📦 Atoms en BDD: #{current}"
    puts "🌍 Atoms sur mainnet: #{total_network}"
    puts "📈 Couverture: #{percent}%"
    puts ""
    puts "📊 Historical Signals: #{HistoricalSignal.count}"
    puts "🔗 Triples: #{Triple.count}"
    puts ""
    
    if current < total_network
      remaining = total_network - current
      batches = (remaining / 250.0).ceil
      minutes = (batches * 1.0 / 60.0).round(1)
      
      puts "⏳ Restant à synchroniser: #{remaining} atoms"
      puts "🔄 Batches nécessaires: #{batches}"
      puts "⏱️  Temps estimé: ~#{minutes} minutes"
      puts ""
      puts "💡 Pour continuer: rake sync:resume"
    else
      puts "✅ Synchronisation COMPLÈTE !"
    end
    
    puts "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  end

  desc "Synchronisation rapide (10,000 atoms recommandés)"
  task quick: :environment do
    puts "⚡ Synchronisation RAPIDE de 10,000 atoms..."
    puts "⏱️  Temps estimé: ~40 secondes"
    puts ""
    
    service = BatchSynchronizationService.new
    stats = service.sync_all_atoms(max_atoms: 10000)
    
    puts ""
    puts "✅ Terminé !"
    puts "📦 Total en BDD: #{Atom.count} atoms"
  end

  desc "Nettoyer toutes les données et resynchroniser"
  task reset: :environment do
    print "⚠️  ATTENTION: Cela va supprimer toutes les données actuelles. Continuer? (y/N): "
    response = STDIN.gets.chomp
    
    if response.downcase == 'y'
      puts "🗑️  Suppression des données..."
      HistoricalSignal.delete_all
      Atom.delete_all
      
      puts "✅ Données supprimées"
      puts "🔄 Relancez 'rake sync:quick' ou 'rake sync:all'"
    else
      puts "❌ Annulé"
    end
  end
end

# Alias pour faciliter
namespace :atoms do
  desc "Synchroniser 10,000 atoms (alias de sync:quick)"
  task sync: 'sync:quick'
  
  desc "Afficher le status (alias de sync:stats)"
  task status: 'sync:stats'
end


