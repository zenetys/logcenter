#!/bin/bash

function url_decode() {
  url_decode=1 var_decode "$@"
}

function var_decode() {
  local prefix="$1" ; shift
  local url_decode=${url_decode:-0}
  local sub var val

  for sub in $*; do
    [[ $sub ]] || continue
    var=${sub%%=*}             # get variable name
    var=${var//[^[:alnum:]]/_} # replace non alnum by '_'
    val=${sub#*=}              # get value
    if (( url_decode == 1 )); then
      val=${val//+/\\x20}        # replace '+' with <SP>
      val=${val//%/\\x}          # replace '%' with \\x (%XX => \xXX)
      val=${val//\\x\\x/%}       # replace \\x\\x (initial double '%') with '%'
    fi
    eval "$prefix${var}=\$'${val}'"
  done
}

# Fonction pour initialiser la base de données d'alias si nécessaire
function init_aliases_db() {
  local db_file="aliases.db"
  
  # Vérifier si la table existe déjà
  if ! sqlite3 "$db_file" "SELECT name FROM sqlite_master WHERE type='table' AND name='aliases';" | grep -q 'aliases'; then
    # Créer la table si elle n'existe pas
    sqlite3 "$db_file" "CREATE TABLE aliases (ip TEXT PRIMARY KEY, hostname TEXT);"
    echo "Table 'aliases' créée dans la base de données $db_file" >&2
  fi
}

# Fonction pour obtenir les alias au format JSON
function get_aliases_json() {
  local db_file="aliases.db"
  sqlite3 -json "$db_file" "SELECT ip, hostname FROM aliases" | jq 'map({( .ip): .hostname}) | add // {}'
}

set -x

# Parse query string parameters
if [[ ${QUERY_STRING} ]]; then
  IFS='&' url_decode _GET_ "$QUERY_STRING"
fi

set >&2

# Initialiser la base de données d'alias
init_aliases_db

if [[ ${REQUEST_URI%%\?*} == "/config.json" ]]; then
    # Obtenir les alias au format JSON
    ALIASES=$(get_aliases_json)

    printf "Status: 200 OK\r\n"
    printf "Content-Type: application/json\r\n\r\n"
    printf '{'
    printf '"status": "ok"'
    printf ',"user_id": "test"'
    printf ',"user_name": "Test User"'
    printf ',"has_kibana": true'
    printf ',"timezone": "CET"'
    printf ',"aliases": %s' "$ALIASES"
    printf '}'
    exit 0
elif [[ ${REQUEST_URI%%\?*} == "/api/config" ]]; then
    # Récupérer les variables ipaddr et alias depuis les paramètres GET
    IPADDR="${_GET_ipaddr:-}"
    ALIAS="${_GET_alias:-}"
    
    # Traitement POC des variables ipaddr et alias
    RESPONSE_STATUS="ok"
    RESPONSE_MESSAGE=""
    
    if [[ -n "$IPADDR" && -n "$ALIAS" ]]; then
        # Enregistrer l'alias dans la base de données
        if sqlite3 aliases.db "INSERT OR REPLACE INTO aliases (ip, hostname) VALUES ('$IPADDR', '$ALIAS');" 2>/dev/null; then
            RESPONSE_MESSAGE="Alias '$ALIAS' enregistré pour l'adresse IP '$IPADDR'"
        else
            RESPONSE_STATUS="error"
            RESPONSE_MESSAGE="Erreur lors de l'enregistrement de l'alias"
        fi
    elif [[ -n "$IPADDR" ]]; then
        # Supprimer l'alias pour cette IP
        if sqlite3 aliases.db "DELETE FROM aliases WHERE ip = '$IPADDR';" 2>/dev/null; then
            RESPONSE_MESSAGE="Alias supprimé pour l'adresse IP '$IPADDR'"
        else
            RESPONSE_STATUS="error"
            RESPONSE_MESSAGE="Erreur lors de la suppression de l'alias"
        fi
    else
        RESPONSE_MESSAGE="Aucune action effectuée. Utilisez les paramètres 'ipaddr' et 'alias' pour définir un alias."
    fi
    
    printf "Status: 200 OK\r\n"
    printf "Content-Type: application/json\r\n\r\n"
    printf '{"status":"%s","message":"%s"}' "$RESPONSE_STATUS" "$RESPONSE_MESSAGE"
    exit 0
fi

printf "Status: 404 Not Found\r\n"
printf "Content-Type: text/plain\r\n\r\n"
printf "Not Found"
exit 0

