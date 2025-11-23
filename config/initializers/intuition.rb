# Configuration pour l'intégration avec le protocole Intuition
# Documentation: https://www.docs.intuition.systems/docs/developer-tools/graphql-api/npm-package

# ═══════════════════════════════════════════════════════════
# INTUITION NETWORK MAINNET (Production) 🟢
# ═══════════════════════════════════════════════════════════
# Chain ID: 1155
# RPC: https://rpc.intuition.systems
# GraphQL: https://mainnet.intuition.sh/v1/graphql ✅
# Explorer: https://explorer.intuition.systems

# ═══════════════════════════════════════════════════════════
# INTUITION NETWORK TESTNET (Development) 🟡
# ═══════════════════════════════════════════════════════════
# Chain ID: 13579
# RPC (HTTP): https://testnet.rpc.intuition.systems/http
# RPC (WebSocket): wss://testnet.rpc.intuition.systems/ws
# GraphQL: https://testnet.intuition.sh/v1/graphql ✅
# Explorer: https://explorer-testnet.intuition.systems

# ═══════════════════════════════════════════════════════════
# CONFIGURATION
# ═══════════════════════════════════════════════════════════
# Pour switcher entre mainnet et testnet :
# export INTUITION_NETWORK=mainnet  (production)
# export INTUITION_NETWORK=testnet  (développement/test)

INTUITION_CONFIG = {
  # 🎯 Réseau par défaut : MAINNET
  network: ENV['INTUITION_NETWORK'] || 'mainnet',
  
  # Mainnet - Réseau de production
  mainnet: {
    chain_id: 1155,
    rpc_url: 'https://rpc.intuition.systems',
    rpc_ws: 'wss://rpc.intuition.systems/ws',
    graphql_url: 'https://mainnet.intuition.sh/v1/graphql',
    explorer: 'https://explorer.intuition.systems',
    name: 'Intuition Mainnet',
    native_token: '$TTRUST'
  },
  
  # Testnet - Réseau de développement
  testnet: {
    chain_id: 13579,
    rpc_url: 'https://testnet.rpc.intuition.systems/http',
    rpc_ws: 'wss://testnet.rpc.intuition.systems/ws',
    graphql_url: 'https://testnet.intuition.sh/v1/graphql',
    explorer: 'https://explorer-testnet.intuition.systems',
    name: 'Intuition Testnet',
    native_token: '$TTRUST'
  }
}.freeze

# Récupérer la config du réseau actif
ACTIVE_NETWORK_CONFIG = INTUITION_CONFIG[INTUITION_CONFIG[:network].to_sym].freeze

# Logging
Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Rails.logger.info "🧠 Intuition Explorer - Connexion Blockchain"
Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Rails.logger.info "  📡 Réseau: #{ACTIVE_NETWORK_CONFIG[:name].upcase}"
Rails.logger.info "  🔗 Chain ID: #{ACTIVE_NETWORK_CONFIG[:chain_id]}"
Rails.logger.info "  💰 Token: #{ACTIVE_NETWORK_CONFIG[:native_token]}"
Rails.logger.info "  🌐 RPC: #{ACTIVE_NETWORK_CONFIG[:rpc_url]}"
Rails.logger.info "  📊 GraphQL: #{ACTIVE_NETWORK_CONFIG[:graphql_url]}"
Rails.logger.info "  🔍 Explorer: #{ACTIVE_NETWORK_CONFIG[:explorer]}"
Rails.logger.info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

