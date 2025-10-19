#!/bin/bash

set -f
umask 0077
PROGNAME=${0##*/}
ZLCCLI=${ZLCCLI:-/opt/logcenter/bin/zlccli}
HEADERS_SENT=

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

cachettl=600

# Parse query string parameters
declare -A params
if [[ -n $QUERY_STRING ]]; then
    IFS='&' read -ra pairs <<< "$QUERY_STRING"
    for pair in "${pairs[@]}"; do
        IFS='=' read -r key value <<< "$pair"
        params[$key]=$(printf '%b' "${value//%/\\x}")
    done
fi

# Build SQL WHERE clause from date parameters
where_clause="1"
if [[ -n ${params[start]} ]] && [[ -n ${params[end]} ]]; then
    where_clause="date(timestamp) >= '${params[start]}' AND date(timestamp) <= '${params[end]}'"
fi

# Handle granularity parameter for aggregation
granularity="${params[granularity]:-hour}"
case "$granularity" in
    day)
        # Aggregate by day
        select_fields="host as hostname, sum(doc_count) as docs, sum(size_bytes) as size, date(timestamp) || ' 00:00:00' as date"
        group_by="GROUP BY hostname, date(timestamp)"
        ;;
    month)
        # Aggregate by month
        select_fields="host as hostname, sum(doc_count) as docs, sum(size_bytes) as size, strftime('%Y-%m-01 00:00:00', timestamp) as date"
        group_by="GROUP BY hostname, strftime('%Y-%m', timestamp)"
        ;;
    hour|*)
        # Default: no aggregation, return hourly data
        select_fields="host as hostname, doc_count as docs, size_bytes as size, strftime('%Y-%m-%d %H:%M:%S', timestamp) as date"
        group_by=""
        ;;
esac

cachefile="$(id -un).${PROGNAME}.${params[start]:-all}.${params[end]:-all}.${granularity:-hour}" || fatal 'Failed to set cache filename'
cachefile="${TMPDIR:-/dev/shm}/${cachefile//[^[:alnum:]]/_}"
lockfile="$cachefile.lock"
now=$(date +%s) || fatal 'Failed to get time'

if [[ ! -f $cachefile.json ]] ||
    (( now - $(stat -c %Y "$cachefile.json") > cachettl )) ||
    [[ $0 -nt $cachefile.json ]]; then

    (
        flock -w 5 9 || fatal 'Failed to take lock'
        ${ZLCCLI} list-indices-aggregated "$select_fields" "$where_clause" "$group_by" > "$cachefile" || {
            rm -f "$cachefile.json"; fatal 'Could not save zlccli output'; }
        tsv2json < "$cachefile" > "$cachefile.json" || retval=2 || {
            rm -f "$cachefile.json"; fatal 'Could not save json encoded output'; }
    ) 9>"$lockfile" || exit $?
fi

headers 200 'content-type: application/json'
cat "$cachefile.json"
