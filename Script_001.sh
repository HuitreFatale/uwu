#!/bin/bash

# ID 1: Fonction d'aide - affiche le message d'usage du script
afficher_aide() {
  echo "Usage: ./log_analyzer.sh <commande> <logfile>"
  echo "Commandes disponibles:"
  echo "  aggregate: Agréger les données des logs (compter les niveaux de log, trouver les messages les plus fréquents)"
  echo "  time_analysis: Lancer l'analyse temporelle depuis un autre script"
  echo "Si aucune commande n'est fournie, ce message d'aide sera affiché."
}

# ID 2: Fonction d'agrégation des logs - compte les niveaux de log et les messages
aggreguer_logs() {
  url_fichier_log="$1"
  echo "=-= Agrégation du fichier depuis l'URL \"$url_fichier_log\" =-="
  
  # ID 3: Initialisation des compteurs pour les niveaux de log et les messages
  declare -A niveaux_log
  declare -A messages
  lignes_totales=0

  # ID 4: Lecture du fichier de logs directement depuis l'URL avec curl
  curl -s "$url_fichier_log" | while IFS= read -r ligne; do
    lignes_totales=$((lignes_totales + 1))
    
    # ID 5: Extraction du niveau de log et du message à partir de chaque ligne
    niveau=$(echo "$ligne" | awk -F'[][]' '{print $2}')
    message=$(echo "$ligne" | sed -n 's/.*msg="\([^"]*\)".*/\1/p')
    
    # ID 6: Incrémentation des compteurs pour chaque niveau de log
    ((niveaux_log["$niveau"]++))
    
    # ID 7: Incrémentation des compteurs pour chaque message
    ((messages["$message"]++))
  done

  # ID 8: Affichage des résultats d'agrégation pour les niveaux de log
  echo "Comptes par niveau de log:"
  for niveau in trace debug info warn error fatal; do
    echo " - $niveau: ${niveaux_log["$niveau"]}"
  done

  # ID 9: Trouver le message le plus fréquent et le moins fréquent
  message_commun=$(for msg in "${!messages[@]}"; do echo "$msg ${messages[$msg]}"; done | sort -k2 -n | tail -n 1)
  message_rare=$(for msg in "${!messages[@]}"; do echo "$msg ${messages[$msg]}"; done | sort -k2 -n | head -n 1)

  # ID 10: Affichage des messages les plus et moins fréquents
  echo "Message le plus fréquent: \"$message_commun\""
  echo "Message le moins fréquent: \"$message_rare\""
  
  echo "=-= Fin du rapport d'agrégation =-="
}

# ID 11: Exécution principale - vérification des arguments et appel des fonctions correspondantes
if [ $# -lt 2 ]; then
  afficher_aide
  exit 1
fi

commande=$1
url_fichier_log=$2

# ID 12: Traitement des commandes
case "$commande" in
  aggregate)
    aggreguer_logs "$url_fichier_log"
    ;;
  time_analysis)
    echo "L'analyse temporelle sera lancée avec le script séparé."
    ./log_analyzer_time.sh "$url_fichier_log"
    ;;
  *)
    echo "Commande inconnue: $commande"
    afficher_aide
    exit 1
    ;;
esac
