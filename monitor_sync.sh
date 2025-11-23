#!/bin/bash

# Script de monitoring de la synchronisation

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 MONITORING SYNCHRONISATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Vérifier si le processus tourne
if ps aux | grep -q "[r]ails runner.*sync"; then
    echo "✅ Processus actif"
    echo ""
else
    echo "❌ Aucun processus de synchronisation détecté"
    echo "💡 Lancez: rails runner 'BatchSynchronizationService.new.sync_all_atoms'"
    exit 1
fi

# Afficher la progression toutes les 2 secondes
while true; do
    clear
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📊 SYNCHRONISATION EN COURS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "🕐 $(date '+%H:%M:%S')"
    echo ""
    
    # Compter les atoms
    CURRENT=$(rails runner "puts Atom.count" 2>/dev/null)
    TARGET=164907
    
    if [ -n "$CURRENT" ]; then
        PERCENT=$(echo "scale=2; $CURRENT * 100 / $TARGET" | bc)
        REMAINING=$((TARGET - CURRENT))
        
        echo "📦 Atoms: $CURRENT / $TARGET"
        echo "📈 Progression: $PERCENT%"
        echo "⏳ Restant: $REMAINING atoms"
        echo ""
        
        # Barre de progression
        FILLED=$((CURRENT * 50 / TARGET))
        printf "["
        for i in $(seq 1 $FILLED); do printf "█"; done
        for i in $(seq $FILLED 49); do printf "░"; done
        printf "]\n"
        echo ""
    fi
    
    # Afficher les dernières lignes du log
    if [ -f /tmp/intuition_full_sync.log ]; then
        echo "📄 Derniers messages:"
        tail -5 /tmp/intuition_full_sync.log | grep -E "(Batch|Progression|✅)" | tail -3
    fi
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "💡 Appuyez sur Ctrl+C pour quitter le monitoring"
    echo "   (la synchronisation continuera en arrière-plan)"
    
    # Vérifier si le processus tourne toujours
    if ! ps aux | grep -q "[r]ails runner.*sync"; then
        echo ""
        echo "✅ SYNCHRONISATION TERMINÉE !"
        break
    fi
    
    sleep 2
done


