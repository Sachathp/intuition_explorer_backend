# Script de test pour vérifier l'appel previewRedeem

require 'net/http'
require 'json'

# Configuration
RPC_URL = 'https://rpc.intuition.systems'
MULTIVAULT_ADDRESS = '0x430BbF52503Bd4801E51182f4cB9f8F534225DE5'

# Données de test (position Satoshi Nakamoto)
VAULT_ID = '0xb5f494c37c11c02c0839a241f5b7d81418f512d0ee63aa02ce47b8bd8342b8ac'
SHARES_WEI = '54110000000000000000' # 54.11 shares

def call_preview_redeem
  # On va d'abord tester avec getSharesValue qui est plus standard
  # getSharesValue(uint256 vaultId, uint256 shares) returns (uint256)
  
  uri = URI(RPC_URL)
  http = Net::HTTP.new(uri.host, uri.port)
  http.use_ssl = true
  
  # Fonction signature: getSharesValue(bytes32,uint256)
  # Keccak256("getSharesValue(bytes32,uint256)") = 0x...
  # Pour l'instant on teste avec un appel de lecture du total_assets du vault
  
  request = Net::HTTP::Post.new('/', {'Content-Type' => 'application/json'})
  request.body = {
    jsonrpc: '2.0',
    method: 'eth_call',
    params: [
      {
        to: MULTIVAULT_ADDRESS,
        data: '0x...' # À compléter
      },
      'latest'
    ],
    id: 1
  }.to_json
  
  response = http.request(request)
  puts "Response: #{response.body}"
end

# Test
call_preview_redeem
