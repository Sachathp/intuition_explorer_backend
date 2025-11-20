class Api::V1::AtomsController < ApplicationController
  before_action :set_atom, only: [:show]
  
  # GET /api/v1/atoms
  # Retourne les atoms triés par signal value décroissant
  def index
    limit = params[:limit]&.to_i || 10
    atoms = Atom.top_by_signal.limit(limit)
    
    render json: {
      atoms: atoms.as_json(only: [:id, :did, :description, :current_signal_value, :share_price, :created_at, :updated_at]),
      count: atoms.count,
      total: Atom.count
    }
  end

  # GET /api/v1/atoms/:id
  # Retourne un atom spécifique avec ses détails
  def show
    # Récupérer les détails supplémentaires depuis l'API si nécessaire
    intuition_service = IntuitionService.new
    atom_details = intuition_service.fetch_atom(@atom.did)
    
    atom_data = @atom.as_json(only: [:id, :did, :description, :current_signal_value, :share_price, :created_at, :updated_at])
    
    # Ajouter les triples si disponibles
    atom_data[:triples] = atom_details[:triples] if atom_details && atom_details[:triples]
    
    render json: { atom: atom_data }
  end
  
  private
  
  def set_atom
    @atom = Atom.find_by(id: params[:id]) || Atom.find_by(did: params[:id])
    
    unless @atom
      render json: { error: 'Atom non trouvé' }, status: :not_found
    end
  end
end
