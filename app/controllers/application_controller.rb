class ApplicationController < ActionController::API
  # Helper pour accéder à la configuration Intuition depuis les controllers
  def intuition_config
    @intuition_config ||= load_intuition_config
  end
  
  def active_network_config
    @active_network_config ||= load_active_network_config
  end
  
  def intuition_network_name
    active_network_config[:name]
  end
  
  private
  
  def load_intuition_config
    {
      network: ENV['INTUITION_NETWORK'] || 'mainnet',
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
  end
  
  def load_active_network_config
    network = ENV['INTUITION_NETWORK'] || 'mainnet'
    load_intuition_config[network.to_sym]
  end
end
