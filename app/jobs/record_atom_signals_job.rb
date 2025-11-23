class RecordAtomSignalsJob < ApplicationJob
  queue_as :default

  def perform
    Rails.logger.info "🔄 Démarrage de l'enregistrement des signaux historiques..."
    
    recorded_count = 0
    Atom.find_each do |atom|
      atom.record_historical_signal
      recorded_count += 1
    end
    
    Rails.logger.info "✅ #{recorded_count} signaux historiques enregistrés"
    recorded_count
  end
end
