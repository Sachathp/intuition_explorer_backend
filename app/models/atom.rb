class Atom < ApplicationRecord
  validates :did, presence: true, uniqueness: true
  
  # Scopes pour le classement
  scope :top_by_signal, -> { order(current_signal_value: :desc) }
  scope :top_by_share_price, -> { order(share_price: :desc) }
  
  # Méthode de recherche lexicale simple
  def self.search(query)
    return all if query.blank?
    
    where("description ILIKE :query OR did ILIKE :query", query: "%#{query}%")
  end
end
