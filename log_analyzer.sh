#!/bin/bash

# Vérifier si un fichier et une commande sont fournis en argument
if [ $# -lt 2 ]; then
  echo "Usage: ./log_analyzer.sh <command> <logfile>"
  echo "Commands:"
  echo "  aggregate          Aggregate log data and count log levels."
  echo "  temporal_analysis  Analyze logs by time and identify the most active and error-prone hours."
  exit 1
fi

command=$1
logfile=$2

# Vérifier si le fichier de logs existe
if [ ! -f "$logfile" ]; then
  echo "Le fichier spécifié n'existe pas : $logfile"
  exit 1
fi

# Effectuer l'agrégation des logs si la commande est 'aggregate'
if [ "$command" == "aggregate" ]; then
  echo =-= Aggregating file "$logfile" =-=

  # Initialisation des compteurs pour chaque niveau de log
  compteur_trace=0
  compteur_debug=0
  compteur_info=0
  compteur_avertissement=0
  compteur_erreur=0
  compteur_fatal=0

  # Initialisation des variables pour l'analyse des messages
  tous_les_messages=()

  # Lire le fichier ligne par ligne
  while IFS= read -r ligne; do
    # Vérifier et incrémenter les compteurs de niveaux de logs en cherchant uniquement les balises [niveau]
    if [[ "$ligne" =~ \[trace\] ]]; then
      ((compteur_trace++))
    elif [[ "$ligne" =~ \[debug\] ]]; then
      ((compteur_debug++))
    elif [[ "$ligne" =~ \[info\] ]]; then
      ((compteur_info++))
    elif [[ "$ligne" =~ \[warn\] ]]; then
      ((compteur_avertissement++))
    elif [[ "$ligne" =~ \[error\] ]]; then
      ((compteur_erreur++))
    elif [[ "$ligne" =~ \[fatal\] ]]; then
      ((compteur_fatal++))
    fi

    # Extraire le message dans msg="..." et ajouter à la liste des messages
    if [[ "$ligne" =~ msg=\"([^\"]+)\" ]]; then
      tous_les_messages+=("${BASH_REMATCH[1]}")
    fi
  done < "$logfile"

  # Affichage des résultats des niveaux de logs
  echo "Log level counts:"
  echo " - trace: $compteur_trace"
  echo " - debug: $compteur_debug"
  echo " - info: $compteur_info"
  echo " - warn: $compteur_avertissement"
  echo " - error: $compteur_erreur"
  echo " - fatal: $compteur_fatal"

  # Si des messages ont été trouvés
  if [ ${#tous_les_messages[@]} -gt 0 ]; then
    # Créer un fichier temporaire pour les messages
    temp=$(mktemp)
    for message in "${tous_les_messages[@]}"; do
      echo "$message" >> "$temp"
    done

    # Extraire le message le plus commun
    message_plus_commun=$(sort "$temp" | uniq -c | sort -nr | head -n 1 | sed 's/^[ \t]*//')
    most_common_msg_count=$(echo "$message_plus_commun" | awk '{print $1}')
    most_common_msg=$(echo "$message_plus_commun" | sed 's/^[ \t]*[0-9]*[ \t]*//')

    # Extraire le message le moins commun
    message_moins_commun=$(sort "$temp" | uniq -c | sort -n | head -n 1 | sed 's/^[ \t]*//')
    least_common_msg_count=$(echo "$message_moins_commun" | awk '{print $1}')
    least_common_msg=$(echo "$message_moins_commun" | sed 's/^[ \t]*[0-9]*[ \t]*//')

    # Afficher les messages les plus et moins communs
    echo -e "Most common message: \"$most_common_msg\" (count: $most_common_msg_count)"
    echo -e "Least common message: \"$least_common_msg\" (count: $least_common_msg_count)"

    # Supprimer le fichier temporaire
    rm -f "$temp"
  else
    echo "Aucun message trouvé dans les logs (msg=\"...\")."
  fi

  echo =-= End of report =-=

# Effectuer l'analyse temporelle si la commande est 'temporal_analysis'
elif [ "$command" == "temporal_analysis" ]; then
  echo =-= "$logfile" temporal analysis =-=

  # Variables pour les jours et heures
  declare -A jours_actifs
  declare -A heures_actives
  declare -A erreurs_heures

  # Lire le fichier ligne par ligne
  while IFS= read -r ligne; do
    # Extraire les informations de date, heure, niveau de log
    if [[ "$ligne" =~ \[([a-zA-Z]+)\].*([0-9]{4}-[0-9]{2}-[0-9]{2})T([0-9]{2}):([0-9]{2}):([0-9]{2}) ]]; then
      jour_semaine=${BASH_REMATCH[1]}
      heure=${BASH_REMATCH[3]}

      # Compter les jours et les heures
      ((jours_actifs[$jour_semaine]++))
      ((heures_actives[$heure]++))

      # Si l'on trouve une erreur ou un fatal
      if [[ "$ligne" =~ \[error\] || "$ligne" =~ \[fatal\] ]]; then
        ((erreurs_heures[$heure]++))
      fi
    fi
  done < "$logfile"

  # Jour le plus actif
  most_active_day=$(for day in "${!jours_actifs[@]}"; do echo "$day ${jours_actifs[$day]}"; done | sort -k2 -nr | head -n 1 | awk '{print $1}')
  echo "Most active day: $most_active_day"

  # Heure la plus active
  most_active_hour=$(for hour in "${!heures_actives[@]}"; do echo "$hour ${heures_actives[$hour]}"; done | sort -k2 -nr | head -n 1 | awk '{print $1}')
  echo "Most active hour: ${most_active_hour}h"

  # Heure la plus "error-prone"
  most_error_prone_hour=$(for hour in "${!erreurs_heures[@]}"; do echo "$hour ${erreurs_heures[$hour]}"; done | sort -k2 -nr | head -n 1 | awk '{print $1}')
  echo "Most error-prone hour: ${most_error_prone_hour}h"

  echo =-= End of report =-=

else
  echo "Commande inconnue : $command. Utilisez 'aggregate' ou 'temporal_analysis'."
  exit 1
fi
