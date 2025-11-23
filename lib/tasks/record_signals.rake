namespace :atoms do
  desc "Enregistre les signaux actuels de tous les atoms dans l'historique"
  task record_signals: :environment do
    puts "🔄 Enregistrement des signaux historiques..."
    result = RecordAtomSignalsJob.perform_now
    puts "✅ #{result} signaux enregistrés"
  end
  
  desc "Génère des données historiques d'exemple pour les 7 derniers jours"
  task generate_historical_data: :environment do
    puts "🔄 Génération de données historiques d'exemple..."
    
    Atom.find_each do |atom|
      # Créer des données pour les 7 derniers jours, toutes les 6 heures
      7.downto(0) do |days_ago|
        4.times do |period|
          hours_ago = (days_ago * 24) + (period * 6)
          recorded_at = hours_ago.hours.ago
          
          # Simuler une variation aléatoire autour de la valeur actuelle
          variation_factor = 1 + ((rand(-20..20)) / 100.0)
          
          HistoricalSignal.create(
            atom: atom,
            signal_value: atom.current_signal_value * variation_factor,
            share_price: atom.share_price * variation_factor,
            recorded_at: recorded_at
          )
        end
      end
      
      puts "  ✅ Données historiques créées pour #{atom.description[0..50]}..."
    end
    
    puts "✅ Génération terminée. Total: #{HistoricalSignal.count} enregistrements"
  end
end


