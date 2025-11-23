class HistoricalSignal < ApplicationRecord
  belongs_to :atom
  
  validates :recorded_at, presence: true
  
  # Scopes pour récupérer les données historiques
  scope :for_atom, ->(atom_id) { where(atom_id: atom_id) }
  scope :recent, -> { order(recorded_at: :desc) }
  scope :oldest_first, -> { order(recorded_at: :asc) }
  scope :within_period, ->(start_time, end_time) { where(recorded_at: start_time..end_time) }
  scope :last_24_hours, -> { where('recorded_at >= ?', 24.hours.ago) }
  scope :last_7_days, -> { where('recorded_at >= ?', 7.days.ago) }
  scope :last_30_days, -> { where('recorded_at >= ?', 30.days.ago) }
end
