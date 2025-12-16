class Atom < ApplicationRecord
  # Désactiver Single Table Inheritance (STI) car nous utilisons le champ 'type' pour stocker le type d'Atom Intuition
  self.inheritance_column = nil
  
  has_many :historical_signals, dependent: :destroy
  
  validates :did, presence: true, uniqueness: true
  
  # Seuil minimum de market cap (100 Trust)
  MINIMUM_MARKET_CAP = 100.0
  
  # Scopes pour le classement
  scope :top_by_market_cap, -> { order(market_cap: :desc) }
  scope :top_by_signal, -> { order(current_signal_value: :desc) }
  scope :top_by_share_price, -> { order(share_price: :desc) }
  
  # Scope pour filtrer les atoms avec un market cap minimum
  # IMPORTANT: Pour l'instant on utilise current_signal_value comme proxy du market cap
  # car la vraie formule du market cap Intuition n'est pas share_price × total_shares
  scope :with_minimum_market_cap, -> { where('current_signal_value > ?', MINIMUM_MARKET_CAP) }
  
  # Le market cap est désormais fourni directement par l'API Intuition
  # Il ne nécessite pas de calcul supplémentaire, la valeur est déjà correcte
  def calculate_market_cap
    # Le market_cap est défini lors du sync avec l'API
    # On s'assure juste qu'il a une valeur par défaut
    self.market_cap ||= 0.0
  end
  
  # Hook pour calculer le market cap avant sauvegarde
  before_save :calculate_market_cap
  
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
  
  # Historique pour graphique (dernières N heures)
  def history_for_chart_hours(hours = 1)
    historical_signals
      .where('recorded_at >= ?', hours.hours.ago)
      .order(recorded_at: :asc)
      .select(:recorded_at, :signal_value, :share_price)
  end
end
