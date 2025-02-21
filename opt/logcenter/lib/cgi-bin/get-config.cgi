#!/bin/bash

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

function fatal() {
    headers 500 'content-type: text/plain'
    echo "FATAL: $PROGNAME: $*" >&2
    exit 2
}

headers 200 'content-type: application/json'
jq -n \
    --arg "user_id" "$HTTP_REMOTE_USER" \
    --arg "user_name" "$HTTP_REMOTE_NAME" \
    --arg "groups" "$HTTP_REMOTE_GROUPS" \
    --arg "timezone" "$(date +%Z)" \
'
{
    user_id: (if $user_id and ($user_id |length) > 0 then $user_id else null end),
    user_name: (if $user_name and ($user_name |length) > 0 then $user_name else null end),
    has_kibana: ((($groups//"")|split(",")|index("opt_kibana")) != null),

    # FIXME: ment to be the timezone of the archiver
    timezone: $timezone,
}
'
