class RecordAtomSignalsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "🔄 Démarrage de l'enregistrement des signaux historiques..."
    
    recorded_count = 0
    # Enregistrer uniquement les signaux des atoms avec market cap > 100 Trust
    Atom.with_minimum_market_cap.find_each do |atom|
      atom.record_historical_signal
      recorded_count += 1
    end
    
    Rails.logger.info "✅ #{recorded_count} signaux historiques enregistrés"
    recorded_count
  end
end
