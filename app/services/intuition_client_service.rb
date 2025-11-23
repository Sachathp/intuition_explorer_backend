# Service client pour interroger le protocole Intuition
# Basé sur le plan migratedata.md - Étape 1: Client Protocolaire
# Schéma GraphQL: https://mainnet.intuition.sh/v1/graphql

class IntuitionClientService
  include HTTParty
  
  # Conversion Wei -> ETH (18 décimales)
  WEI_TO_ETH = 1_000_000_000_000_000_000.0
  
  def initialize
    @config = load_network_config
    @headers = {
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
    
    # Utiliser l'endpoint GraphQL configuré
    self.class.base_uri(@config[:graphql_url])
    
    Rails.logger.info "🔗 IntuitionClientService initialisé - #{@config[:name]}"
  end
  
  def load_network_config
    network = ENV['INTUITION_NETWORK'] || 'mainnet'
    
    config = {
      mainnet: {
        chain_id: 1155,
        rpc_url: 'https://rpc.intuition.systems',
        rpc_ws: 'wss://rpc.intuition.systems/ws',
        graphql_url: 'https://mainnet.intuition.sh/v1/graphql',
        explorer: 'https://explorer.intuition.systems',
        name: 'Intuition Mainnet',
        native_token: '$TTRUST'
      },
      testnet: {
        chain_id: 13579,
        rpc_url: 'https://testnet.rpc.intuition.systems/http',
        rpc_ws: 'wss://testnet.rpc.intuition.systems/ws',
        graphql_url: 'https://testnet.intuition.sh/v1/graphql',
        explorer: 'https://explorer-testnet.intuition.systems',
        name: 'Intuition Testnet',
        native_token: '$TTRUST'
      }
    }
    
    config[network.to_sym]
  end
  
  # ═══════════════════════════════════════════════════════════
  # ÉTAPE 1.3: Requêtes de Base (MVP)
  # ═══════════════════════════════════════════════════════════
  
  # Extraire les atoms avec leurs données complètes
  def fetch_atoms_from_network(options = {})
    limit = options[:limit] || 100
    order_by = options[:order_by] || 'created_at'
    order_direction = options[:order_direction] || 'desc'
    
    query = build_atoms_query(limit, order_by, order_direction)
    result = execute_graphql_query(query)
    
    return [] unless result && result['atoms']
    
    parse_atoms(result['atoms'])
  end
  
  # Extraire les atoms avec pagination (pour synchronisation complète)
  def fetch_atoms_with_pagination(offset: 0, limit: 250)
    query = build_atoms_query_with_offset(offset, limit)
    result = execute_graphql_query(query)
    
    return [] unless result && result['atoms']
    
    parse_atoms(result['atoms'])
  end
  
  # Extraire un atom spécifique avec ses détails complets
  def fetch_atom_by_id(atom_id)
    query = build_atom_detail_query(atom_id)
    result = execute_graphql_query(query)
    
    return nil unless result && result['atoms'] && result['atoms'].first
    
    parse_atom_detail(result['atoms'].first)
  end
  
  # ═══════════════════════════════════════════════════════════
  # ÉTAPE 3.1: Extraction des Triples
  # ═══════════════════════════════════════════════════════════
  
  # Récupère tous les triples associés à un atom (comme sujet, prédicat ou objet)
  def fetch_triples_for_atom(atom_id)
    query = build_triples_query(atom_id)
    result = execute_graphql_query(query)
    
    return [] unless result
    
    parse_triples(result)
  end
  
  # Récupère les statistiques générales du réseau
  def fetch_network_stats
    query = build_stats_query
    result = execute_graphql_query(query)
    
    return {} unless result && result['atoms_aggregate']
    
    {
      total_atoms: result['atoms_aggregate']['aggregate']['count']
    }
  end
  
  private
  
  # ═══════════════════════════════════════════════════════════
  # EXECUTION GraphQL
  # ═══════════════════════════════════════════════════════════
  
  def execute_graphql_query(query)
    Rails.logger.debug "🔍 Executing GraphQL query to #{@config[:graphql_url]}..."
    
    response = self.class.post(
      '',
      headers: @headers,
      body: { query: query }.to_json,
      timeout: 30
    )
    
    if response.success?
      result = response.parsed_response
      
      if result['errors']
        Rails.logger.error "❌ GraphQL Errors: #{result['errors']}"
        return nil
      end
      
      Rails.logger.debug "✅ Query successful"
      result['data']
    else
      Rails.logger.error "❌ HTTP Error: #{response.code} - #{response.message}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "❌ Request failed: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    nil
  end
  
  # ═══════════════════════════════════════════════════════════
  # CONSTRUCTION DES REQUÊTES GraphQL (Schéma Réel Intuition)
  # ═══════════════════════════════════════════════════════════
  
  def build_atoms_query(limit, order_by, order_direction)
    <<~GRAPHQL
      query {
        atoms(
          limit: #{limit}, 
          order_by: { #{order_by}: #{order_direction} }
        ) {
          term_id
          label
          image
          type
          creator_id
          wallet_id
          block_number
          created_at
          term {
            id
            deposits_aggregate {
              aggregate {
                sum {
                  assets_after_fees
                  shares
                }
                count
              }
            }
            positions_aggregate {
              aggregate {
                count
              }
            }
            share_price_change_stats_daily(
              limit: 1, 
              order_by: { bucket: desc }
            ) {
              first_share_price
              last_share_price
              difference
            }
            share_price_change_stats_weekly(
              limit: 1, 
              order_by: { bucket: desc }
            ) {
              first_share_price
              last_share_price
              difference
            }
          }
        }
      }
    GRAPHQL
  end
  
  def build_atoms_query_with_offset(offset, limit)
    <<~GRAPHQL
      query {
        atoms(
          offset: #{offset},
          limit: #{limit}, 
          order_by: { created_at: desc }
        ) {
          term_id
          label
          image
          type
          creator_id
          wallet_id
          block_number
          created_at
          term {
            id
            deposits_aggregate {
              aggregate {
                sum {
                  assets_after_fees
                  shares
                }
                count
              }
            }
            positions_aggregate {
              aggregate {
                count
              }
            }
            share_price_change_stats_daily(
              limit: 1, 
              order_by: { bucket: desc }
            ) {
              first_share_price
              last_share_price
              difference
            }
            share_price_change_stats_weekly(
              limit: 1, 
              order_by: { bucket: desc }
            ) {
              first_share_price
              last_share_price
              difference
            }
          }
        }
      }
    GRAPHQL
  end
  
  def build_atom_detail_query(atom_id)
    <<~GRAPHQL
      query {
        atoms(where: { term_id: { _eq: "#{atom_id}" } }) {
          term_id
          label
          image
          type
          creator_id
          wallet_id
          block_number
          created_at
          data
          emoji
          term {
            id
            deposits_aggregate {
              aggregate {
                sum {
                  assets_after_fees
                  shares
                }
                count
              }
            }
            positions_aggregate {
              aggregate {
                count
              }
            }
            share_price_change_stats_daily(
              limit: 7, 
              order_by: { bucket: desc }
            ) {
              bucket
              first_share_price
              last_share_price
              difference
            }
          }
          as_subject_triples(limit: 20) {
            id
            predicate: term_object {
              term_id
              label
            }
            object: term_object_1 {
              term_id
              label
            }
          }
        }
      }
    GRAPHQL
  end
  
  def build_triples_query(atom_id)
    <<~GRAPHQL
      query {
        as_subject: atoms(where: { term_id: { _eq: "#{atom_id}" } }) {
          as_subject_triples(limit: 20) {
            id
            subject: term_subject { term_id label }
            predicate: term_object { term_id label }
            object: term_object_1 { term_id label }
          }
        }
        as_predicate: atoms(where: { term_id: { _eq: "#{atom_id}" } }) {
          as_predicate_triples(limit: 20) {
            id
            subject: term_subject { term_id label }
            predicate: term_object { term_id label }
            object: term_object_1 { term_id label }
          }
        }
        as_object: atoms(where: { term_id: { _eq: "#{atom_id}" } }) {
          as_object_triples(limit: 20) {
            id
            subject: term_subject { term_id label }
            predicate: term_object { term_id label }
            object: term_object_1 { term_id label }
          }
        }
      }
    GRAPHQL
  end
  
  def build_stats_query
    <<~GRAPHQL
      query {
        atoms_aggregate {
          aggregate {
            count
          }
        }
      }
    GRAPHQL
  end
  
  # ═══════════════════════════════════════════════════════════
  # PARSING DES RÉSULTATS
  # ═══════════════════════════════════════════════════════════
  
  def parse_atoms(atoms_data)
    atoms_data.map do |atom|
      parse_atom(atom)
    end.compact
  end
  
  def parse_atom(atom_data)
    term = atom_data['term']
    deposits = term&.dig('deposits_aggregate', 'aggregate')
    stats_daily = term&.dig('share_price_change_stats_daily')&.first
    stats_weekly = term&.dig('share_price_change_stats_weekly')&.first
    
    {
      did: atom_data['term_id'],
      description: atom_data['label'],
      image: atom_data['image'],
      type: atom_data['type'],
      creator: atom_data['creator_id'],
      wallet: atom_data['wallet_id'],
      
      # Métriques financières (conversion Wei -> ETH)
      current_signal_value: convert_wei_to_eth(deposits&.dig('sum', 'assets_after_fees')),
      share_price: convert_wei_to_eth(stats_daily&.dig('last_share_price')),
      total_shares: convert_wei_to_eth(deposits&.dig('sum', 'shares')),
      
      # Statistiques
      deposits_count: deposits&.dig('count') || 0,
      positions_count: term&.dig('positions_aggregate', 'aggregate', 'count') || 0,
      
      # Prix de référence pour calcul de croissance (24h)
      first_price_24h: convert_wei_to_eth(stats_daily&.dig('first_share_price')),
      price_change_24h: convert_wei_to_eth(stats_daily&.dig('difference')),
      
      # Prix de référence pour calcul de croissance (7d)
      first_price_7d: convert_wei_to_eth(stats_weekly&.dig('first_share_price')),
      price_change_7d: convert_wei_to_eth(stats_weekly&.dig('difference')),
      
      # Métadonnées
      created_at: atom_data['created_at'],
      block_number: atom_data['block_number']
    }
  end
  
  def parse_atom_detail(atom_data)
    base = parse_atom(atom_data)
    
    # Ajouter les triples
    triples = atom_data['as_subject_triples']&.map do |triple|
      {
        id: triple['id'],
        subject_id: atom_data['term_id'],
        subject_label: atom_data['label'],
        predicate_id: triple.dig('predicate', 'term_id'),
        predicate_label: triple.dig('predicate', 'label'),
        object_id: triple.dig('object', 'term_id'),
        object_label: triple.dig('object', 'label')
      }
    end || []
    
    base.merge(
      triples: triples,
      data: atom_data['data'],
      emoji: atom_data['emoji']
    )
  end
  
  def parse_triples(result)
    all_triples = []
    
    ['as_subject', 'as_predicate', 'as_object'].each do |role|
      atoms = result[role]
      next unless atoms && atoms.first
      
      key = "#{role}_triples"
      triples = atoms.first[key] || []
      
      triples.each do |triple|
        all_triples << {
          id: triple['id'],
          subject_id: triple.dig('subject', 'term_id'),
          subject_label: triple.dig('subject', 'label'),
          predicate_id: triple.dig('predicate', 'term_id'),
          predicate_label: triple.dig('predicate', 'label'),
          object_id: triple.dig('object', 'term_id'),
          object_label: triple.dig('object', 'label'),
          role: role
        }
      end
    end
    
    all_triples.uniq { |t| t[:id] }
  end
  
  # Conversion Wei (18 décimales) vers ETH
  def convert_wei_to_eth(value)
    return 0.0 if value.nil? || value.to_s.empty? || value.to_s == "0"
    value.to_f / WEI_TO_ETH
  end
end
