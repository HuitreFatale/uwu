#!/bin/bash

# Vérifier si un fichier est fourni en argument
if [ -z "$1" ]; then
  echo "Veuillez fournir un fichier de logs en argument."
  exit 1
fi

logfile=$1

# Vérifier si le fichier existe
if [ ! -f "$logfile" ]; then
  echo "Le fichier spécifié n'existe pas : $logfile"
  exit 1
fi

# Afficher le message d'agrégation
echo =-= Aggregating file "logfile.log" =-=
echo Log level counts:

# Initialisation des compteurs pour chaque niveau de
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
echo "Comptage des niveaux de :"
echo " - trace: $compteur_trace"
echo " - debug: $compteur_debug"
echo " - info: $compteur_info"
echo " - avertissement: $compteur_avertissement"
echo " - erreur: $compteur_erreur"
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

  # Extraire le message le moins commun
  message_moins_commun=$(sort "$temp" | uniq -c | sort -n | head -n 1 | sed 's/^[ \t]*//')

  # Afficher les messages les plus et moins communs
  echo -e "Message le plus commun : \"$message_plus_commun\""
  echo -e "Message le moins commun : \"$message_moins_commun\""

  # Supprimer le fichier temporaire
  rm -f "$temp"
else
  echo "Aucun message trouvé dans les logs (msg=\"...\")."
fi

echo "-w- Fin du rapport -w-"
