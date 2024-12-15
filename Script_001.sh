#!/bin/bash

# aide
aide() {
  echo "Usage : ./log_analyzer.sh <commande> <fichier_log>"
  echo "Commandes dispo :"
  echo "  aggregate : agréger les données des logs"
  echo "  time_analysis : analyser les logs par heure"
}

# Fonction qui va agréger les logs en comptant les occurrences des niveaux
agreg() {
  fichier_log="$1"
  echo "OwO Agrégation du fichier \"$fichier_log\" OwO"

  # Initialisation des compteurs, histoire de savoir combien on en a
  declare -A niveaux
  declare -A messages
  total_lignes=0

  # Lire le fichier log et traiter chaque ligne
  curl -s "$fichier_log" | while IFS= read -r ligne; do
    total_lignes=$((total_lignes + 1))
    
    # On extrait le niveau de log (trace, debug, etc.)
    niveau=$(echo "$ligne" | awk -F'[][]' '{print $2}')
    
    # Et le message de log
    message=$(echo "$ligne" | sed -n 's/.*msg="\([^"]*\)".*/\1/p')
    
    # incrémentation
    ((niveaux["$niveau"]++))
    ((messages["$message"]++))
  done

  # Afficher les résultats des niveaux de logs
  echo "Comptage des niveaux de log :"
  for niveau in trace debug info warn error fatal; do
    echo " - $niveau: ${niveaux["$niveau"]}"
  done

  # messages la plus fréquents
  message_commun=$(for msg in "${!messages[@]}"; do echo "$msg ${messages[$msg]}"; done | sort -k2 -n | tail -n 1)
  message_moins_commun=$(for msg in "${!messages[@]}"; do echo "$msg ${messages[$msg]}"; done | sort -k2 -n | head -n 1)

  # mzssage les moins fréquents
  echo "Message le plus commun : \"$message_commun\""
  echo "Message le moins commun : \"$message_moins_commun\""
  
  echo "-w- Fin du rapport -w-"
}

# Fonction analyser les logs par heure
parh() {
  fichier_log="$1"
  echo "UwU Analyse temporelle UwU"
  
  # Compteur d'activité et d'erreurs par heure
  declare -A activite
  declare -A erreurs
  
  # Lire les logs et analyser l'heure de chaque entrée
  curl -s "$fichier_log" | while IFS= read -r ligne; do
    heure=$(echo "$ligne" | awk '{print $2}' | cut -d'T' -f2 | cut -d':' -f1)
    niveau=$(echo "$ligne" | awk -F'[][]' '{print $2}')

    # On compte les erreurs (fatal ou error)
    if [[ "$niveau" == "error" || "$niveau" == "fatal" ]]; then
      ((erreurs["$heure"]++))
    fi
    ((activite["$heure"]++))
  done

  # Afficher les heures les plus actives
  echo "Les heures les plus actives :"
  for heure in "${!activite[@]}"; do
    echo " - $heure: ${activite[$heure]} logs"
  done | sort -k2 -n | tail -n 5

  # Afficher les heures avec le plus d'erreurs
  echo "Les heures avec le plus d'erreurs :"
  for heure in "${!erreurs[@]}"; do
    echo " - $heure: ${erreurs[$heure]} erreurs"
  done | sort -k2 -n | tail -n 5

  echo "-w- Fin de l'analyse temporelle -w-"
}

# Smauvais arguments --> aide
if [ $# -lt 2 ]; then
  aide
  exit 1
fi

commande=$1
fichier_log=$2

# Choisir l'action à faire en fonction de la commande
case "$commande" in
  aggregate)
    agreg "$fichier_log"
    ;;
  time_analysis)
    parh "$fichier_log"
    ;;
  *)
    echo "Commande inconnue : $commande"
    aide
    exit 1
    ;;
esac
