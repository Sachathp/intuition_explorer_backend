# Fichier de seed pour des données d'exemple
puts "🌱 Création de données d'exemple pour Intuition Explorer..."

# Nettoyer les données existantes
Atom.destroy_all

# Créer des Atoms d'exemple
atoms_data = [
  {
    did: "did:intuition:atom:0x1234567890abcdef1234567890abcdef12345678",
    description: "Bitcoin est une cryptomonnaie décentralisée créée en 2009 par Satoshi Nakamoto. Elle permet des transactions peer-to-peer sans intermédiaire.",
    current_signal_value: 2500.75,
    share_price: 125.50
  },
  {
    did: "did:intuition:atom:0xabcdef1234567890abcdef1234567890abcdef12",
    description: "Ethereum est une plateforme blockchain open-source avec fonctionnalité de contrats intelligents. ETH est sa cryptomonnaie native.",
    current_signal_value: 2100.25,
    share_price: 110.30
  },
  {
    did: "did:intuition:atom:0x9876543210fedcba9876543210fedcba98765432",
    description: "La blockchain est une technologie de stockage et de transmission d'informations, transparente, sécurisée et fonctionnant sans organe central de contrôle.",
    current_signal_value: 1850.00,
    share_price: 98.75
  },
  {
    did: "did:intuition:atom:0xfedcba9876543210fedcba9876543210fedcba98",
    description: "Les smart contracts sont des programmes informatiques qui exécutent automatiquement des conditions prédéfinies sur la blockchain.",
    current_signal_value: 1500.50,
    share_price: 85.20
  },
  {
    did: "did:intuition:atom:0x1111222233334444555566667777888899990000",
    description: "Le Web3 représente la troisième génération d'Internet basée sur la décentralisation et les technologies blockchain.",
    current_signal_value: 1200.00,
    share_price: 72.15
  },
  {
    did: "did:intuition:atom:0xaaaa1111bbbb2222cccc3333dddd4444eeee5555",
    description: "DeFi (Finance Décentralisée) fait référence aux services financiers construits sur des blockchains publiques, principalement Ethereum.",
    current_signal_value: 980.30,
    share_price: 65.40
  },
  {
    did: "did:intuition:atom:0x5555eeee4444dddd3333cccc2222bbbb1111aaaa",
    description: "Les NFTs (Non-Fungible Tokens) sont des jetons numériques uniques représentant la propriété d'actifs numériques ou physiques.",
    current_signal_value: 750.80,
    share_price: 52.90
  },
  {
    did: "did:intuition:atom:0x1234abcd5678efgh9012ijkl3456mnop7890qrst",
    description: "Un wallet crypto est un portefeuille numérique permettant de stocker, envoyer et recevoir des cryptomonnaies de manière sécurisée.",
    current_signal_value: 620.45,
    share_price: 45.30
  },
  {
    did: "did:intuition:atom:0xqrst7890mnop3456ijkl9012efgh5678abcd1234",
    description: "Le consensus Proof of Stake (PoS) est un mécanisme où les validateurs sont choisis en fonction de leur participation (stake) dans le réseau.",
    current_signal_value: 450.25,
    share_price: 38.70
  },
  {
    did: "did:intuition:atom:0xzzzz9999yyyy8888xxxx7777wwww6666vvvv5555",
    description: "Les DAOs (Organisations Autonomes Décentralisées) sont des organisations gouvernées par des smart contracts et gérées par leurs membres.",
    current_signal_value: 320.15,
    share_price: 28.50
  },
  {
    did: "did:intuition:atom:0x0000ffff1111eeee2222dddd3333cccc4444bbbb",
    description: "Le staking consiste à verrouiller des cryptomonnaies pour sécuriser un réseau blockchain et recevoir des récompenses en retour.",
    current_signal_value: 180.60,
    share_price: 18.90
  },
  {
    did: "did:intuition:atom:0xbbbb4444cccc3333dddd2222eeee1111ffff0000",
    description: "Les bridges blockchain permettent le transfert d'actifs et d'informations entre différentes blockchains.",
    current_signal_value: 95.40,
    share_price: 12.25
  },
  {
    did: "did:intuition:atom:0x1a2b3c4d5e6f7g8h9i0j1k2l3m4n5o6p7q8r9s0t",
    description: "Le gas fee représente les frais de transaction payés pour effectuer des opérations sur la blockchain Ethereum.",
    current_signal_value: 65.20,
    share_price: 8.75
  },
  {
    did: "did:intuition:atom:0xt0s9r8q7p6o5n4m3l2k1j0i9h8g7f6e5d4c3b2a1",
    description: "Les Layer 2 sont des solutions de scalabilité construites au-dessus des blockchains principales pour améliorer les performances.",
    current_signal_value: 42.10,
    share_price: 5.50
  },
  {
    did: "did:intuition:atom:0xdeadbeefcafebabe1337133713371337deadbeef",
    description: "Un oracle blockchain est un service tiers qui fournit des données du monde réel aux smart contracts.",
    current_signal_value: 25.30,
    share_price: 3.20
  }
]

atoms_data.each do |atom_data|
  atom = Atom.create!(atom_data)
  puts "  ✅ Créé: #{atom.description[0..50]}... (Signal: #{atom.current_signal_value})"
end

puts "\n🎉 #{Atom.count} Atoms créés avec succès!"
puts "🏆 Top 3 Atoms par Signal:"

Atom.top_by_signal.limit(3).each_with_index do |atom, index|
  puts "  #{index + 1}. #{atom.description[0..60]}... (#{atom.current_signal_value})"
end
