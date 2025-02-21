#!/bin/bash

set -f
umask 0077
PROGNAME=${0##*/}
HEADERS_SENT=

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
cachefile="$(id -un).${PROGNAME}" || fatal 'Failed to set cache filename'
cachefile="${TMPDIR:-/dev/shm}/${cachefile//[^[:alnum:]]/_}"
lockfile="$cachefile.lock"
now=$(date +%s) || fatal 'Failed to get time'

if [[ ! -f $cachefile.json ]] ||
    (( now - $(stat -c %Y "$cachefile.json") > cachettl )) ||
    [[ $0 -nt $cachefile.json ]]; then

    (
        flock -w 5 9 || fatal 'Failed to take lock'
        /opt/logcenter/bin/zlccli list-archives > "$cachefile" || {
            rm -f "$cachefile.json"; fatal 'Could not save zlccli output'; }
        db2json < "$cachefile" > "$cachefile.json" || retval=2 || {
            rm -f "$cachefile.json"; fatal 'Could not save json encoded output'; }
    ) 9>"$lockfile" || exit $?
fi

headers 200 'content-type: application/json'
cat "$cachefile.json"
