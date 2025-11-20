class Api::V1::SyncController < ApplicationController
  # POST /api/v1/sync
  # Synchronise les atoms depuis l'API Intuition
  def create
    intuition_service = IntuitionService.new
    synced_count = intuition_service.sync_atoms
    
    render json: {
      success: true,
      message: "#{synced_count} atoms synchronisés avec succès",
      synced_count: synced_count,
      total_atoms: Atom.count
    }
  rescue StandardError => e
    render json: {
      success: false,
      error: "Erreur lors de la synchronisation: #{e.message}"
    }, status: :internal_server_error
  end
end

