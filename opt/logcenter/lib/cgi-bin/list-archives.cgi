#!/bin/bash

set -f
umask 0077
PROGNAME=${0##*/}
HEADERS_SENT=
ZLCCLI=${ZLCCLI:-/opt/logcenter/bin/zlccli}

function db2json() {
    awk '
    function dump_values() {
        if (RECORD++ > 0) printf(",");
        if (!VALUES["src"]) return;
        printf("{\"%s\":\"%s\"", "hostname", VALUES["src"]);
        printf(",\"%s\":%d", "line", VALUES["lines"]);
        printf(",\"%s\":%d", "size", VALUES["bytes"]);
        printf(",\"%s\":\"%s %02d:00:00\"", "date", VALUES["fdate"], VALUES["fhour"]);
        printf("}");
    }
    BEGIN {
        FS = "\t";
        printf("[");
    }
    {
        # get headers
        if (!HEADERS[1]) {
            for (i=1;i<=NF;i++) { HEADERS[i] = $i; NHEADERS[$i] = i; }
            next;
        }

        # dump data if changed
        CURRENT = $NHEADERS["src"]"."$NHEADERS["fdate"]"."$NHEADERS["fhour"];

        if (PREVIOUS && PREVIOUS != CURRENT) {
            dump_values();
            delete(VALUES);
        }
        # aggregate lines
        PREVIOUS = CURRENT;

        # get lines
        for(i=1;i<=NHEADERS["fhour"];i++) VALUES[HEADERS[i]] = $i;
        for(i=NHEADERS["fhour"]+1;i<=NF;i++) VALUES[HEADERS[i]] += $i;
    }
    END {
        dump_values();
        printf("]");
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
    where_clause="fdate >= '${params[start]}' AND fdate <= '${params[end]}'"
fi

# Handle granularity parameter for aggregation
granularity="${params[granularity]:-hour}"
case "$granularity" in
    day)
        # Aggregate by day: sum all hours per day
        select_clause="src as src, fdate as fdate, 0 as fhour, sum(lines) as lines, sum(bytes) as bytes, fdate || ' 00:00:00' as date"
        group_by="GROUP BY src, fdate"
        ;;
    month)
        # Aggregate by month: sum all days per month
        select_clause="src as src, substr(fdate,1,7) || '-01' as fdate, 0 as fhour, sum(lines) as lines, sum(bytes) as bytes, substr(fdate,1,7) || '-01 00:00:00' as date"
        group_by="GROUP BY src, substr(fdate,1,7)"
        ;;
    hour|*)
        # Default: no aggregation, return hourly data
        select_clause="*"
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
        ${ZLCCLI} list-archives-aggregated "$select_clause" "$where_clause" "$group_by" > "$cachefile" || {
            rm -f "$cachefile.json"; fatal 'Could not save zlccli output'; }
        db2json < "$cachefile" > "$cachefile.json" || retval=2 || {
            rm -f "$cachefile.json"; fatal 'Could not save json encoded output'; }
    ) 9>"$lockfile" || exit $?
fi

headers 200 'content-type: application/json'
cat "$cachefile.json"
