#!/bin/bash

set -f
umask 0077
PROGNAME=${0##*/}
HEADERS_SENT=
SCRIPT_DIR=$(dirname "$0")

function headers() {
    [[ -z $HEADERS_SENT ]] || return 0
    HEADERS_SENT=1
    local h
    echo "Status: $1"; shift
    for h in "$@"; do echo "$h"; done
    echo
}

function fatal() {
    headers 500 'content-type: text/plain'
    echo "FATAL: $PROGNAME: $*" >&2
    exit 2
}

function tsv2json() {
    awk '
BEGIN {
  FS="\t"
  RS="\n"
  OFS=""
  printf("[\n");
}

{
  # bypass non multi-fields lines
  if (NF <= 1) {
    delete names;
    lnames = 0;
    next;
  }

  # detect header (starting with "# WORD"), reset headers
  if (lnames == 0) {
    delete names;
    # store headers
    for(i=1;i<=NF;i++) names[++lnames] = ($i);
    next;
  }

  printf("%s{\n", (NR>2)?",":" ");
  for (i=1;i<=length(names);i++) {
    if (match($i, "[0-9]+") && RSTART == 1 && RLENGTH == length($i)) {
      printf("  %s\"%s\": %s\n", ((i>1)?",":" "), names[i], ($i));
    }
    else {
      printf("  %s\"%s\": \"%s\"\n", ((i>1)?",":" "), names[i], gensub("([\"\\\\])","\\\\\\1", "g", ($i)));
    }
  }
  printf("}\n");
}

END {
  printf("]\n");
}
    '
}

# Function to query the SQLite database and format the results as JSON
function get_aliases_json() {
    /opt/logcenter/bin/zlccli list-aliases |
      tsv2json |
      jq 'map({( .ip): .hostname}) | add // {}'
}

# Get aliases from database
ALIASES_JSON=$(get_aliases_json)

headers 200 'content-type: application/json'
jq -n \
    --arg "user_id" "$HTTP_REMOTE_USER" \
    --arg "user_name" "$HTTP_REMOTE_NAME" \
    --arg "groups" "$HTTP_REMOTE_GROUPS" \
    --arg "timezone" "$(date +%Z)" \
    --argjson "aliases" "$ALIASES_JSON" \
'
{
    user_id: (if $user_id and ($user_id |length) > 0 then $user_id else null end),
    user_name: (if $user_name and ($user_name |length) > 0 then $user_name else null end),
    has_kibana: ((($groups//"")|split(",")|index("opt_kibana")) != null),

    # Timezone of the archiver
    timezone: $timezone,

    # Hostname aliases mapping
    aliases: $aliases
}
'
