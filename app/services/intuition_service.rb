class IntuitionService
  include HTTParty
  
  # Configuration pour le réseau Intuition
  # Intuition Network Mainnet (Chain ID: 1155)
  INTUITION_RPC_URL = 'https://rpc.intuition.systems'
  # Pour testnet : https://rpc-testnet.intuition.systems (Chain ID: 13579)
  
  # URL du Subgraph/Indexer GraphQL (à confirmer avec la communauté)
  # Utilisation temporaire d'un endpoint de simulation pour développement
  GRAPHQL_ENDPOINT = ENV['INTUITION_GRAPHQL_URL'] || 'https://portal-api.intuition.systems/graphql'
  
  base_uri GRAPHQL_ENDPOINT
  
  def initialize
    @headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
    @rpc_url = INTUITION_RPC_URL
  end
  
  # Récupère les atoms depuis l'API Intuition
  def fetch_atoms(limit: 100)
    query = <<~GRAPHQL
      query {
        atoms(first: #{limit}, orderBy: signalValue, orderDirection: desc) {
          id
          data {
            description
          }
          signalValue
          sharePrice
        }
      }
    GRAPHQL
    
    response = self.class.post(
      '',
      headers: @headers,
      body: { query: query }.to_json
    )
    
    if response.success?
      parse_atoms_response(response.parsed_response)
    else
      Rails.logger.error("Erreur lors de la récupération des atoms: #{response.code}")
      []
    end
  rescue StandardError => e
    Rails.logger.error("Erreur lors de la communication avec l'API Intuition: #{e.message}")
    []
  end
  
  # Récupère un atom spécifique par son ID
  def fetch_atom(did)
    query = <<~GRAPHQL
      query {
        atom(id: "#{did}") {
          id
          data {
            description
          }
          signalValue
          sharePrice
          triples {
            subject {
              id
              data {
                description
              }
            }
            predicate {
              id
              data {
                description
              }
            }
            object {
              id
              data {
                description
              }
            }
          }
        }
      }
    GRAPHQL
    
    response = self.class.post(
      '',
      headers: @headers,
      body: { query: query }.to_json
    )
    
    if response.success?
      parse_atom_response(response.parsed_response)
    else
      Rails.logger.error("Erreur lors de la récupération de l'atom #{did}: #{response.code}")
      nil
    end
  rescue StandardError => e
    Rails.logger.error("Erreur lors de la communication avec l'API Intuition: #{e.message}")
    nil
  end
  
  # Synchronise les atoms de l'API avec la base de données locale
  def sync_atoms
    atoms_data = fetch_atoms
    synced_count = 0
    
    atoms_data.each do |atom_data|
      atom = Atom.find_or_initialize_by(did: atom_data[:did])
      atom.assign_attributes(atom_data.except(:did))
      
      if atom.save
        synced_count += 1
      else
        Rails.logger.warn("Impossible de sauvegarder l'atom #{atom_data[:did]}: #{atom.errors.full_messages.join(', ')}")
      end
    end
    
    Rails.logger.info("#{synced_count} atoms synchronisés avec succès")
    synced_count
  end
  
  private
  
  def parse_atoms_response(response)
    return [] unless response.dig('data', 'atoms')
    
    response['data']['atoms'].map do |atom|
      {
        did: atom['id'],
        description: atom.dig('data', 'description') || '',
        current_signal_value: atom['signalValue'].to_f,
        share_price: atom['sharePrice'].to_f
      }
    end
  end
  
  def parse_atom_response(response)
    return nil unless response.dig('data', 'atom')
    
    atom = response['data']['atom']
    {
      did: atom['id'],
      description: atom.dig('data', 'description') || '',
      current_signal_value: atom['signalValue'].to_f,
      share_price: atom['sharePrice'].to_f,
      triples: atom['triples']&.map { |triple| parse_triple(triple) } || []
    }
  end
  
  def parse_triple(triple)
    {
      subject: {
        id: triple.dig('subject', 'id'),
        description: triple.dig('subject', 'data', 'description')
      },
      predicate: {
        id: triple.dig('predicate', 'id'),
        description: triple.dig('predicate', 'data', 'description')
      },
      object: {
        id: triple.dig('object', 'id'),
        description: triple.dig('object', 'data', 'description')
      }
    }
  end
end

