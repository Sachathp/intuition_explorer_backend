# Service pour calculer la vraie valeur de rachat des positions Intuition
# Utilise le smart contract EthMultiVault.previewRedeem()

class VaultValueCalculatorService
  include HTTParty
  
  # Function selector pour previewRedeem(uint256 shares, uint256 id)
  # keccak256("previewRedeem(uint256,uint256)")[:4] = 0x4cdad506
  PREVIEW_REDEEM_SELECTOR = '4cdad506'
  
  WEI_TO_ETH = 1_000_000_000_000_000_000.0
  
  def initialize
    @config = load_network_config
    @rpc_url = @config[:rpc_url]
    @multivault_address = @config[:multivault_address]
    
    self.class.base_uri(@rpc_url)
    
    Rails.logger.info "🔧 VaultValueCalculator initialized - #{@config[:name]}"
  end
  
  def load_network_config
    network = ENV['INTUITION_NETWORK'] || 'mainnet'
    
    config = {
      mainnet: {
        name: 'Intuition Mainnet',
        chain_id: 1155,
        rpc_url: 'https://rpc.intuition.systems',
        multivault_address: '0x430BbF52503Bd4801E51182f4cB9f8F534225DE5'
      },
      testnet: {
        name: 'Intuition Testnet',
        chain_id: 13579,
        rpc_url: 'https://testnet.rpc.intuition.systems/http',
        multivault_address: '0x...' # À compléter si besoin
      }
    }
    
    config[network.to_sym]
  end
  
  # Calcule une approximation de la valeur de rachat basée sur le slippage de la bonding curve
  # @param shares_wei [String|Integer] Le nombre de shares en Wei
  # @param vault_total_shares_wei [String|Integer] Le total de shares du vault
  # @param current_share_price_wei [String|Integer] Le prix marginal actuel
  # @return [Float] La valeur approximative en TRUST
  def calculate_redeem_value_approximate(shares_wei, vault_total_shares_wei, current_share_price_wei)
    return 0.0 if shares_wei.to_i.zero?
    
    begin
      # Convertir en float
      shares = shares_wei.to_f / WEI_TO_ETH
      vault_total_shares = vault_total_shares_wei.to_f / WEI_TO_ETH
      current_price = current_share_price_wei.to_f / WEI_TO_ETH
      
      # Valeur naïve (sans slippage)
      naive_value = shares * current_price
      
      # Calculer le ratio de propriété
      ownership_ratio = shares / vault_total_shares
      
      # Facteur de correction basé sur le slippage observé
      # Plus on possède de shares, plus le slippage est important
      correction_factor = if ownership_ratio < 0.001  # <0.1% du vault
                            0.95  # Peu de slippage
                          elsif ownership_ratio < 0.01  # <1% du vault
                            0.85  # Slippage modéré
                          elsif ownership_ratio < 0.10  # <10% du vault
                            0.70  # Slippage important
                          elsif ownership_ratio < 0.50  # <50% du vault
                            0.65  # Slippage très important
                          else  # >50% du vault
                            0.60  # Slippage extrême
                          end
      
      # Appliquer la correction
      approximate_value = naive_value * correction_factor
      
      Rails.logger.debug "💡 Approximate value calculation:"
      Rails.logger.debug "   Shares: #{shares} (#{(ownership_ratio * 100).round(2)}% of vault)"
      Rails.logger.debug "   Naive value: #{naive_value.round(2)} TRUST"
      Rails.logger.debug "   Correction factor: #{correction_factor}"
      Rails.logger.debug "   Approximate value: #{approximate_value.round(2)} TRUST"
      
      approximate_value
      
    rescue StandardError => e
      Rails.logger.error "❌ Error in approximate calculation: #{e.message}"
      # Fallback sur le calcul naïf
      (shares_wei.to_f / WEI_TO_ETH) * (current_share_price_wei.to_f / WEI_TO_ETH)
    end
  end
  
  # Calcule les valeurs pour un batch de positions
  # @param positions [Array<Hash>] Liste de positions avec :vault_id et :shares_wei
  # @return [Hash] Map vault_id+shares => real_value
  def calculate_batch(positions)
    results = {}
    
    positions.each do |position|
      key = "#{position[:vault_id]}_#{position[:shares_wei]}"
      value = calculate_redeem_value(position[:vault_id], position[:shares_wei])
      results[key] = value if value
    end
    
    results
  end
  
  private
  
  # Effectue un appel eth_call au smart contract
  def eth_call(calldata)
    payload = {
      jsonrpc: '2.0',
      method: 'eth_call',
      params: [
        {
          to: @multivault_address,
          data: calldata
        },
        'latest'
      ],
      id: rand(1..10000)
    }
    
    response = self.class.post(
      '',
      headers: { 'Content-Type' => 'application/json' },
      body: payload.to_json,
      timeout: 10
    )
    
    if response.success?
      result = response.parsed_response['result']
      
      if response.parsed_response['error']
        Rails.logger.error "RPC Error: #{response.parsed_response['error']}"
        return nil
      end
      
      result
    else
      Rails.logger.error "HTTP Error: #{response.code}"
      nil
    end
  rescue StandardError => e
    Rails.logger.error "Request failed: #{e.message}"
    nil
  end
  
  # Convertit un nombre en uint256 hex (64 caractères)
  def uint256_to_hex(value)
    # Supprimer le préfixe 0x si présent et convertir en entier
    int_value = value.to_s.gsub(/^0x/, '').to_i(value.to_s.match?(/^0x/) ? 16 : 10)
    int_value.to_s(16).rjust(64, '0')
  end
  
  # Convertit hex en integer
  def hex_to_int(hex_string)
    hex_string.gsub(/^0x/, '').to_i(16)
  end
end
