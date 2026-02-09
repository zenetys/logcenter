#!/bin/bash

export LC_ALL=C

set -f
umask 0077
PROGNAME=${0##*/}
HEADERS_SENT=

function headers() {
    [[ -z $HEADERS_SENT ]] || return 0
    HEADERS_SENT=1
    local h
    echo "Status: $1"; shift
    for h in "$@"; do echo "$h"; done
    echo
}

function info() {
    echo "INFO: $PROGNAME: $*" >&2
}

function fatal() {
    headers 500 'content-type: text/plain'
    echo "FATAL: $PROGNAME: $*" >&2
    exit 2
}

max_post_size=$((1024*1024))

[[ $REQUEST_METHOD == POST ]] || fatal 'Bad method'
(( CONTENT_LENGTH > 0 && CONTENT_LENGTH <= max_post_size )) || fatal 'Invalid content-length'

if [[ $CONTENT_TYPE =~ ^application/x-www-form-urlencoded(;.*)?$ ]]; then
    json_input=$(head -c "$max_post_size" |sed -nre '/^data=/{s,^data=,,;p;q}' |
        awk -niord -v RS=%.. -v ORS= '{gsub(/\+/," ");print RT?$0chr("0x"substr(RT,2)):$0}')
elif [[ $CONTENT_TYPE =~ ^application/json(;.*)?$ ]]; then
    json_input=$(head -c "$max_post_size")
else
    fatal 'Bad content type'
fi

OIFS=$IFS; IFS=$'\n'
qarchives=($(echo "$json_input" | jq -r '
if type != "array" then error("invalid input, array") else . end |
map(
    if type != "object" then error("invalid input, object entries") else . end |
    if (.hostname |type) != "string" then error("invalid input, hostname") else . end |
    if (.hostname |length) == 0 then error("invalid input, hostname") else . end |
    if (.rawDate |type) != "string" then error("invalid input, rawDate") else . end |
    if (.rawDate |test("^([0-9]{4}-[0-9]{2}-[0-9]{2}) ([0-9]{2}):00:00$") |not)
        then error("invalid input, rawDate") else . end |
    "\(.hostname),\(.rawDate |sub(" (?<h>[0-9]{2}).*"; ",\(.h|tonumber)"))"
)[]
'))
retval=$?
IFS=$OIFS

(( retval == 0 )) || fatal 'Invalid input!'

info "Parsed archive query: ${qarchives[@]@Q}"
/opt/logcenter/bin/zlccli get-archive --proto "${qarchives[@]}" |
(
    trap '[[ -n $protofile && -f $protofile ]] && rm -f "$protofile"' EXIT
    protofile=$(mktemp) || fatal 'Failed to create proto file'
    head -n 1 > "$protofile" || fatal 'Failed to save proto file'
    [[ $(dd if="$protofile" bs=1 count=3 status=none) == $'\x16\x17\x18' ]] ||
        fatal 'Proto marker not found'
    IFS=$'\x16'
    proto=( $(dd if="$protofile" bs=1 skip=3 status=none) )
    IFS=$OIFS
    info "Parsed proto: ${proto[@]@Q}"
    [[ -z ${proto[0]} || -n ${proto[0]//[[:print:]]} ]] && fatal 'Invalid proto, filename'
    [[ -n ${proto[1]} && -n ${proto[1]//[0-9]} ]] && fatal 'Invalid proto, length'
    headers 200 \
        'content-type: application/octet-stream' \
        "content-disposition: attachment; filename=\"${proto[0]}\"" \
        ${proto[1]:+"content-length: ${proto[1]}"}
    cat
)
