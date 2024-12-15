#!/bin/bash

# Fonction d'aide
aide() {
  echo "Usage : ./Script_001.sh <commande> <fichier_log>"
  echo "Commandes disponibles :"
  echo "  aggregate       : Agréger les données des logs"
  echo "  time_analysis   : Analyser les logs par heure"
  exit 0
}

# Fonction pour lire les données (local ou URL texte brut)
lire_fichier() {
  fichier="$1"
  
  # Vérifie si c'est une URL
  if [[ "$fichier" =~ ^https?:// ]]; then
    echo "Lecture du texte depuis l'URL : $fichier" >&2
    if command -v wget > /dev/null; then
      wget -q -O - "$fichier" || { echo "Erreur : Impossible de récupérer les données depuis l'URL." >&2; exit 1; }
    else
      echo "Erreur : wget n'est pas installé. Installe-le pour continuer." >&2
      exit 1
    fi
  else
    # Sinon, lire le fichier local
    echo "Lecture du fichier local : $fichier" >&2
    if [[ -f "$fichier" ]]; then
      cat "$fichier"
    else
      echo "Erreur : Le fichier \"$fichier\" est introuvable." >&2
      exit 1
    fi
  fi
}

# Fonction pour agréger les logs
agreg() {
  fichier_log="$1"
  echo "OwO Agrégation des logs pour \"$fichier_log\" OwO"
  
  declare -A niveaux
  declare -A messages
  total_lignes=0

  # Lire le contenu et traiter chaque ligne
  lire_fichier "$fichier_log" | while IFS= read -r ligne; do
    total_lignes=$((total_lignes + 1))

    # Extraire le niveau de log (trace, debug, etc.)
    niveau=$(echo "$ligne" | awk -F'[][]' '{print $2}')

    # Extraire le message de log
    message=$(echo "$ligne" | sed -n 's/.*msg="\([^"]*\)".*/\1/p')

    # Incrémenter les compteurs
    if [[ -n "$niveau" ]]; then
      niveaux["$niveau"]=$((niveaux["$niveau"] + 1))
    fi
    if [[ -n "$message" ]]; then
      messages["$message"]=$((messages["$message"] + 1))
    fi
  done

  # Affichage des résultats
  echo "Comptage des niveaux de log :"
  for niveau in trace debug info warn error fatal; do
    echo " - $niveau: ${niveaux["$niveau"]}"
  done

  # Messages les plus fréquents et les moins fréquents
  message_commun=$(for msg in "${!messages[@]}"; do echo "$msg ${messages[$msg]}"; done | sort -k2 -n | tail -n 1)
  message_moins_commun=$(for msg in "${!messages[@]}"; do echo "$msg ${messages[$msg]}"; done | sort -k2 -n | head -n 1)

  echo "Message le plus commun : \"$message_commun\""
  echo "Message le moins commun : \"$message_moins_commun\""
  echo "-w- Fin du rapport -w-"
}

# Fonction pour analyser les logs par heure
parh() {
  fichier_log="$1"
  echo "UwU Analyse temporelle des logs UwU"

  declare -A activite
  declare -A erreurs

  # Lire les données et analyser l'heure
  lire_fichier "$fichier_log" | while IFS= read -r ligne; do
    heure=$(echo "$ligne" | awk '{print $2}' | cut -d'T' -f2 | cut -d':' -f1)
    niveau=$(echo "$ligne" | awk -F'[][]' '{print $2}')

    # Compter les erreurs et l'activité
    if [[ "$niveau" == "error" ]] || [[ "$niveau" == "fatal" ]]; then
      erreurs["$heure"]=$((erreurs["$heure"] + 1))
    fi
    activite["$heure"]=$((activite["$heure"] + 1))
  done

  # Afficher les heures les plus actives
  echo "Les heures les plus actives :"
  for heure in "${!activite[@]}"; do
    echo " - $heure: ${activite["$heure"]} logs"
  done | sort -k2 -n | tail -n 5

  # Afficher les heures avec le plus d'erreurs
  echo "Les heures avec le plus d'erreurs :"
  for heure in "${!erreurs[@]}"; do
    echo " - $heure: ${erreurs["$heure"]} erreurs"
  done | sort -k2 -n | tail -n 5
  echo "-w- Fin de l'analyse temporelle -w-"
}

# Vérifier les arguments
if [[ $# -lt 2 ]]; then
  aide
fi

commande="$1"
fichier_log="$2"

# Exécuter la commande correspondante
if [[ "$commande" == "aggregate" ]]; then
  agreg "$fichier_log"
elif [[ "$commande" == "time_analysis" ]]; then
  parh "$fichier_log"
else
  echo "Commande inconnue : $commande"
  aide
fi
