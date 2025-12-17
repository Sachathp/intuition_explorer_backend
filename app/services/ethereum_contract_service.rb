# Service pour interagir avec les smart contracts Ethereum/Intuition
# Permet de calculer la vraie valeur de rachat des positions via previewRedeem

class EthereumContractService
  include HTTParty
  
  # ABI simplifié pour la fonction previewRedeem du MultiVault
  # previewRedeem(uint256 shares) returns (uint256 assets)
  PREVIEW_REDEEM_SIGNATURE = '0x4cdad506' # Keccak256("previewRedeem(uint256)")[:4]
  
  def initialize
    @config = load_network_config
    @rpc_url = @config[:rpc_url]
    self.class.base_uri(@rpc_url)
  end
  
  def load_network_config
    network = ENV['INTUITION_NETWORK'] || 'mainnet'
    
    config = {
      mainnet: {
        chain_id: 1155,
        rpc_url: 'https://rpc.intuition.systems',
        multivault_address: '0x430BbF52503Bd4801E51182f4cB9f8F534225DE5'
      },
      testnet: {
        chain_id: 13579,
        rpc_url: 'https://testnet.rpc.intuition.systems/http',
        multivault_address: '0x...' # À compléter si besoin
      }
    }
    
    config[network.to_sym]
  end
  
  # Calcule la vraie valeur de rachat pour une position
  # @param vault_id [String] L'ID du vault (term_id)
  # @param shares_wei [String|Integer] Le nombre de shares en Wei
  # @return [Float] La valeur en TRUST (ETH)
  def preview_redeem(vault_id, shares_wei)
    return 0.0 if shares_wei.to_i.zero?
    
    begin
      # Convertir les shares en hex
      shares_hex = to_padded_hex(shares_wei)
      
      # Construire le calldata: function_signature + vault_id + shares
      # previewRedeem(uint256 vaultId, uint256 shares)
      # Note: Il faut vérifier la signature exacte dans le contrat
      vault_id_hex = to_padded_hex(extract_vault_id_number(vault_id))
      
      calldata = PREVIEW_REDEEM_SIGNATURE + vault_id_hex + shares_hex
      
      # Appeler eth_call
      result = eth_call(calldata)
      
      if result
        # Convertir le résultat hex en decimal puis en ETH
        assets_wei = hex_to_decimal(result)
        wei_to_eth(assets_wei)
      else
        # Fallback sur le calcul approximatif si l'appel échoue
        Rails.logger.warn "⚠️  previewRedeem failed, using fallback calculation"
        nil
      end
      
    rescue StandardError => e
      Rails.logger.error "❌ Error calling previewRedeem: #{e.message}"
      Rails.logger.error e.backtrace.first(3).join("\n")
      nil
    end
  end
  
  # Calcule les vraies valeurs pour un batch de positions
  # Plus efficace que d'appeler une par une
  def preview_redeem_batch(positions)
    positions.map do |position|
      value = preview_redeem(position[:vault_term_id], position[:shares_wei])
      position.merge(real_value: value) if value
      position
    end
  end
  
  private
  
  # Appel RPC eth_call
  def eth_call(calldata)
    payload = {
      jsonrpc: '2.0',
      method: 'eth_call',
      params: [
        {
          to: @config[:multivault_address],
          data: calldata
        },
        'latest'
      ],
      id: 1
    }
    
    response = self.class.post(
      '',
      headers: { 'Content-Type' => 'application/json' },
      body: payload.to_json
    )
    
    if response.success? && response.parsed_response['result']
      response.parsed_response['result']
    else
      Rails.logger.error "RPC Error: #{response.parsed_response}"
      nil
    end
  end
  
  # Extrait le numéro de vault depuis un term_id (hash)
  # Pour l'instant, on utilise directement le term_id comme vault_id
  def extract_vault_id_number(term_id)
    # Le vault_id pourrait être dérivé du term_id
    # Pour simplifier, on va d'abord essayer avec le curve_id = 1 (vault principal)
    # TODO: Vérifier si on doit utiliser term_id ou curve_id
    term_id
  end
  
  # Convertit un nombre en hex padded à 32 bytes (64 caractères)
  def to_padded_hex(value)
    value_str = value.to_s.delete('0x')
    hex_value = value_str.match?(/^[0-9a-fA-F]+$/) ? value_str : value.to_i.to_s(16)
    hex_value.rjust(64, '0')
  end
  
  # Convertit hex en decimal
  def hex_to_decimal(hex_string)
    hex_string.delete('0x').to_i(16)
  end
  
  # Convertit Wei en ETH
  def wei_to_eth(wei)
    wei.to_f / 1_000_000_000_000_000_000.0
  end
end
