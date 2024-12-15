#!/bin/bash

# Vérifier si un fichier est fourni en argument
if [ -z "$1" ]; then
  echo "Veuillez fournir un fichier de logs en argument."
  exit 1
fi

LOGFILE=$1

# Vérifier si le fichier existe
if [ ! -f "$LOGFILE" ]; then
  echo "Le fichier spécifié n'existe pas : $LOGFILE"
  exit 1
fi

# Afficher le message d'agrégation
echo "OwO Agrégation des logs pour \"$LOGFILE\" OwO"
echo "Lecture du texte depuis le fichier : $LOGFILE"

# Initialisation des compteurs pour chaque niveau de log
trace_count=0
debug_count=0
info_count=0
warn_count=0
error_count=0
fatal_count=0

# Lire le fichier ligne par ligne
while IFS= read -r line; do
  # Incrémenter les compteurs en fonction des niveaux de log
  if [[ "$line" == *"trace"* ]]; then
    ((trace_count++))
  elif [[ "$line" == *"debug"* ]]; then
    ((debug_count++))
  elif [[ "$line" == *"info"* ]]; then
    ((info_count++))
  elif [[ "$line" == *"warn"* ]]; then
    ((warn_count++))
  elif [[ "$line" == *"error"* ]]; then
    ((error_count++))
  elif [[ "$line" == *"fatal"* ]]; then
    ((fatal_count++))
  fi
done < "$LOGFILE"

# Affichage des résultats
echo "Comptage des niveaux de log :"
echo " - trace: $trace_count"
echo " - debug: $debug_count"
echo " - info: $info_count"
echo " - warn: $warn_count"
echo " - error: $error_count"
echo " - fatal: $fatal_count"

# Extraire le message le plus commun
most_common_message=$(sort "$LOGFILE" | uniq -c | sort -nr | head -n 1 | sed 's/^[ \t]*//')

# Extraire le message le moins commun
least_common_message=$(sort "$LOGFILE" | uniq -c | sort -n | head -n 1 | sed 's/^[ \t]*//')

echo -e "Message le plus commun : \"$most_common_message\""
echo -e "Message le moins commun : \"$least_common_message\""

echo "-w- Fin du rapport -w-"
