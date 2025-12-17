#!/bin/bash
# Script pour démarrer Solid Queue Worker
# Utilisé en développement pour traiter les jobs en arrière-plan

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Démarrage de Solid Queue Worker"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Ce worker va:"
echo "   - Traiter les jobs en arrière-plan"
echo "   - Exécuter les tâches récurrentes configurées"
echo "   - Synchroniser les atoms automatiquement"
echo ""
echo "📅 Tâches récurrentes:"
echo "   - sync_atoms_update: toutes les 6 heures (prod)"
echo ""
echo "⏳ Démarrage..."
echo ""

bundle exec rake solid_queue:start



