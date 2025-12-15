# Service client pour interroger le protocole Intuition
# Basé sur le plan migratedata.md - Étape 1: Client Protocolaire
# Schéma GraphQL: https://mainnet.intuition.sh/v1/graphql

class IntuitionClientService
  include HTTParty
  
  # Conversion Wei -> ETH (18 décimales)
  WEI_TO_ETH = 1_000_000_000_000_000_000.0
  
  # Market cap minimum en Wei (100 TRUST = 100 × 10^18 Wei)
  MIN_MARKET_CAP_WEI = (100 * WEI_TO_ETH).to_i.to_s
  
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
    offset = options[:offset] || 0
    order_by = options[:order_by] || 'created_at'
    order_direction = options[:order_direction] || 'desc'
    
    # Utiliser la méthode avec offset si fourni
    if offset > 0
      query = build_atoms_query_with_offset(offset, limit)
    else
      query = build_atoms_query(limit, order_by, order_direction)
    end
    
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
          order_by: { #{order_by}: #{order_direction} },
          where: { term: { total_market_cap: { _gt: "#{MIN_MARKET_CAP_WEI}" } } }
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
            total_market_cap
            total_assets
            vaults(order_by: {market_cap: desc}, limit: 1) {
              current_share_price
              market_cap
              total_assets
              total_shares
              position_count
            }
            share_price_changes(limit: 1, order_by: {block_number: desc}) {
              share_price
              block_number
            }
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
                sum {
                  shares
                }
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
          order_by: { created_at: desc },
          where: { term: { total_market_cap: { _gt: "#{MIN_MARKET_CAP_WEI}" } } }
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
            total_market_cap
            total_assets
            vaults(order_by: {market_cap: desc}, limit: 1) {
              current_share_price
              market_cap
              total_assets
              total_shares
              position_count
            }
            share_price_changes(limit: 1, order_by: {block_number: desc}) {
              share_price
              block_number
            }
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
                sum {
                  shares
                }
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
            total_market_cap
            total_assets
            vaults(order_by: {market_cap: desc}, limit: 1) {
              current_share_price
              market_cap
              total_assets
              total_shares
              position_count
            }
            share_price_changes(limit: 1, order_by: {block_number: desc}) {
              share_price
              block_number
            }
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
                sum {
                  shares
                }
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
            subject: term_subject { term_id label }
            predicate: term_object { term_id label }
            object: term_object_1 { term_id label }
          }
        }
        as_predicate: atoms(where: { term_id: { _eq: "#{atom_id}" } }) {
          as_predicate_triples(limit: 20) {
            subject: term_subject { term_id label }
            predicate: term_object { term_id label }
            object: term_object_1 { term_id label }
          }
        }
        as_object: atoms(where: { term_id: { _eq: "#{atom_id}" } }) {
          as_object_triples(limit: 20) {
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
    positions = term&.dig('positions_aggregate', 'aggregate')
    stats_daily = term&.dig('share_price_change_stats_daily')&.first
    stats_weekly = term&.dig('share_price_change_stats_weekly')&.first
    # Récupérer le dernier changement de prix (prix actuel)
    latest_price_change = term&.dig('share_price_changes')&.first
    
    # IMPORTANT: Récupérer le vault principal (avec le plus gros market_cap)
    # C'est ce vault qui contient le vrai current_share_price
    main_vault = term&.dig('vaults')&.first
    
    # Log pour déboguer les valeurs brutes
    if main_vault
      Rails.logger.debug "🔍 Main vault current_share_price (atom: #{atom_data['term_id']}): #{main_vault['current_share_price']}"
    end
    
    # Récupérer le share_price du vault principal (prioritaire) ou fallback sur l'ancien système
    if main_vault && main_vault['current_share_price']
      share_price_value = convert_wei_to_eth(main_vault['current_share_price'])
      Rails.logger.debug "💰 Using vault share_price: #{share_price_value} TRUST"
    else
      share_price_value = get_share_price(latest_price_change, stats_daily, stats_weekly)
      Rails.logger.debug "💰 Using fallback share_price: #{share_price_value} TRUST"
    end
    
    positions_shares = convert_wei_to_eth(positions&.dig('sum', 'shares'))
    
    # IMPORTANT: Utiliser total_market_cap et total_assets directement de l'API
    # Ces valeurs sont calculées par Intuition et correspondent à leur interface officielle
    total_market_cap_from_api = convert_wei_to_eth(term&.dig('total_market_cap'))
    total_assets_from_api = convert_wei_to_eth(term&.dig('total_assets'))
    
    {
      did: atom_data['term_id'],
      description: atom_data['label'],
      image: atom_data['image'],
      type: atom_data['type'],
      creator: atom_data['creator_id'],
      wallet: atom_data['wallet_id'],
      
      # Métriques financières (conversion Wei -> TRUST)
      # Signal Value = Total des assets déposés (assets_after_fees)
      current_signal_value: convert_wei_to_eth(deposits&.dig('sum', 'assets_after_fees')),
      # Market Cap = Valeur directe de l'API (calculée par Intuition)
      market_cap: total_market_cap_from_api,
      # Total Assets = Valeur directe de l'API
      total_assets: total_assets_from_api,
      # Share Price = Prix actuel depuis share_price_changes (dernier changement), avec fallback sur stats
      share_price: share_price_value,
      # Total Shares = Shares dans les dépôts (total locked)
      total_shares: convert_wei_to_eth(deposits&.dig('sum', 'shares')),
      # Positions Shares = Shares détenues par les holders actifs
      positions_shares: positions_shares,
      
      # Statistiques
      deposits_count: deposits&.dig('count') || 0,
      positions_count: positions&.dig('count') || 0,
      
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
      # Générer un ID unique basé sur la combinaison sujet-prédicat-objet
      subject_id = atom_data['term_id']
      predicate_id = triple.dig('predicate', 'term_id')
      object_id = triple.dig('object', 'term_id')
      triple_id = "#{subject_id}-#{predicate_id}-#{object_id}"
      
      {
        id: triple_id,
        subject_id: subject_id,
        subject_label: atom_data['label'],
        predicate_id: predicate_id,
        predicate_label: triple.dig('predicate', 'label'),
        object_id: object_id,
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
        # Générer un ID unique basé sur la combinaison sujet-prédicat-objet
        subject_id = triple.dig('subject', 'term_id')
        predicate_id = triple.dig('predicate', 'term_id')
        object_id = triple.dig('object', 'term_id')
        triple_id = "#{subject_id}-#{predicate_id}-#{object_id}"
        
        all_triples << {
          id: triple_id,
          subject_id: subject_id,
          subject_label: triple.dig('subject', 'label'),
          predicate_id: predicate_id,
          predicate_label: triple.dig('predicate', 'label'),
          object_id: object_id,
          object_label: triple.dig('object', 'label'),
          role: role
        }
      end
    end
    
    all_triples.uniq { |t| t[:id] }
  end
  
  # Conversion Wei (18 décimales) vers TRUST/ETH
  def convert_wei_to_eth(value)
    return 0.0 if value.nil? || value.to_s.empty? || value.to_s == "0"
    value.to_f / WEI_TO_ETH
  end
  
  # Récupère le prix des shares avec priorité sur le dernier changement de prix
  def get_share_price(latest_price_change, stats_daily, stats_weekly)
    # Priorité 1: share_price depuis le dernier changement (prix spot actuel)
    if latest_price_change && latest_price_change['share_price']
      raw_price = latest_price_change['share_price']
      # Détecter si la valeur est déjà en TRUST (petite valeur) ou en Wei (très grande valeur)
      price = normalize_price(raw_price)
      if price > 0
        Rails.logger.debug "💰 Share price from latest change: #{price} TRUST (raw: #{raw_price}, block: #{latest_price_change['block_number']})"
        return price
      end
    end
    
    # Priorité 2: last_share_price des stats journalières
    if stats_daily && stats_daily['last_share_price']
      raw_price = stats_daily['last_share_price']
      price = normalize_price(raw_price)
      if price > 0
        Rails.logger.debug "💰 Share price from daily stats: #{price} TRUST (raw: #{raw_price})"
        return price
      end
    end
    
    # Priorité 3: last_share_price des stats hebdomadaires
    if stats_weekly && stats_weekly['last_share_price']
      raw_price = stats_weekly['last_share_price']
      price = normalize_price(raw_price)
      if price > 0
        Rails.logger.debug "💰 Share price from weekly stats: #{price} TRUST (raw: #{raw_price})"
        return price
      end
    end
    
    # Fallback: 0 si aucune valeur disponible
    Rails.logger.warn "⚠️  No share price found - latest_change: #{latest_price_change&.dig('share_price')}, daily: #{stats_daily&.dig('last_share_price')}, weekly: #{stats_weekly&.dig('last_share_price')}"
    0.0
  end
  
  # Normalise le prix : détecte si c'est déjà en TRUST ou en Wei
  def normalize_price(raw_value)
    return 0.0 if raw_value.nil? || raw_value.to_s.empty? || raw_value.to_s == "0"
    
    value = raw_value.to_f
    
    # Si la valeur est très grande (> 1e15), c'est probablement en Wei, on convertit
    # Si la valeur est petite (< 1e15), c'est probablement déjà en TRUST
    if value > 1_000_000_000_000_000 # 1e15
      # Conversion Wei -> TRUST
      converted = value / WEI_TO_ETH
      Rails.logger.debug "🔢 Price appears to be in Wei: #{value} -> #{converted} TRUST"
      converted
    else
      # Déjà en TRUST
      Rails.logger.debug "🔢 Price appears to be already in TRUST: #{value}"
      value
    end
  end
end
