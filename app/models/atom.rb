class Atom < ApplicationRecord
  # Désactiver Single Table Inheritance (STI) car nous utilisons le champ 'type' pour stocker le type d'Atom Intuition
  self.inheritance_column = nil
  
  has_many :historical_signals, dependent: :destroy
  
  validates :did, presence: true, uniqueness: true
  
  # Scopes pour le classement
  scope :top_by_signal, -> { order(current_signal_value: :desc) }
  scope :top_by_share_price, -> { order(share_price: :desc) }
  
  # Méthode de recherche lexicale simple
  def self.search(query)
    return all if query.blank?
    
    where("description ILIKE :query OR did ILIKE :query", query: "%#{query}%")
  end
  
  # Enregistre un snapshot historique des valeurs actuelles
  def record_historical_signal
    historical_signals.create(
      signal_value: current_signal_value,
      share_price: share_price,
      recorded_at: Time.current
    )
  end
  
  # Calcule la croissance sur une période donnée
  def growth_over_period(hours)
    period_ago = hours.hours.ago
    old_signal = historical_signals
                  .where('recorded_at <= ?', period_ago)
                  .order(recorded_at: :desc)
                  .first
    
    return nil unless old_signal && old_signal.signal_value.positive?
    
    ((current_signal_value - old_signal.signal_value) / old_signal.signal_value) * 100
  end
  
  # Croissance sur 24 heures
  def growth_24h
    growth_over_period(24)
  end
  
  # Croissance sur 7 jours
  def growth_7d
    growth_over_period(24 * 7)
  end
  
  # Historique pour graphique (derniers N jours)
  def history_for_chart(days = 7)
    historical_signals
      .where('recorded_at >= ?', days.days.ago)
      .order(recorded_at: :asc)
      .select(:recorded_at, :signal_value, :share_price)
  end
end
