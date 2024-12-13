#!/bin/bash
#CHAT GPT !!!!!!
FICHIER="$1"

if [[ ! -f "$FICHIER" ]]; then
    echo "Erreur : Le fichier $FICHIER n'existe pas."
    exit 1
fi

echo "Analyse des anomalies dans le fichier : $FICHIER"

# Lignes mal formées
echo "Lignes mal formées :"
grep -nvE '^\[(trace|debug|info|warn|error|fatal)\] [0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}(\.[0-9]+)?([+-][0-9]{2}:[0-9]{2})? msg=".*"$' "$FICHIER" > malformees.log
echo "  - Résultats sauvegardés dans malformees.log"

# Niveaux de logs inhabituels
echo "Niveaux de log inhabituels :"
grep -oE '^\[[a-z]+\]' "$FICHIER" | grep -vE '^\[(trace|debug|info|warn|error|fatal)\]' > niveaux_inhabituels.log
echo "  - Résultats sauvegardés dans niveaux_inhabituels.log"

# Messages absents ou mal formés
echo "Messages absents ou mal formés :"
grep -nv 'msg=".*"' "$FICHIER" > messages_absents.log
echo "  - Résultats sauvegardés dans messages_absents.log"

echo "Analyse terminée. Consulte les fichiers :"
echo "  - malformees.log pour les lignes mal formées"
echo "  - niveaux_inhabituels.log pour les niveaux de log inhabituels"
echo "  - messages_absents.log pour les messages absents ou mal formés"

