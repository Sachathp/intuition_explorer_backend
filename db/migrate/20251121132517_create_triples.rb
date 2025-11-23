class CreateTriples < ActiveRecord::Migration[8.0]
  def change
    create_table :triples do |t|
      t.string :triple_id, null: false    # ID unique du triple depuis Intuition
      t.string :subject_id, null: false   # DID du sujet (Atom)
      t.string :predicate_id, null: false # DID du prédicat (relation)
      t.string :object_id, null: false    # DID de l'objet (Atom cible)
      t.string :vault_id                  # ID du vault associé
      
      # Labels pour affichage rapide (dénormalisé)
      t.string :subject_label
      t.string :predicate_label
      t.string :object_label
      
      # Métriques économiques
      t.decimal :total_deposited, precision: 30, scale: 18, default: 0.0
      t.decimal :counter_deposited, precision: 30, scale: 18, default: 0.0

      t.timestamps
    end
    
    # Index pour performances
    add_index :triples, :triple_id, unique: true
    add_index :triples, :subject_id
    add_index :triples, :predicate_id
    add_index :triples, :object_id
    add_index :triples, :vault_id
    add_index :triples, [:subject_id, :predicate_id, :object_id], name: 'index_triples_on_spo'
  end
end
