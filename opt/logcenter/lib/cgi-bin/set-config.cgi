#!/usr/bin/bash

# Debug logging
set -f
# exec 2>>/tmp/${0##*/}.debug
# set >&2
# set -x

# Find the aliases database in the same directory as this script
PROGNAME=$(basename "$0")
SCRIPT_DIR=$(dirname "$0")

function info() {
  local status=${status:-ok}
  local message="$1"
  # Include proper CGI headers with Status header that Vite expects
  printf "Content-Type: application/json\r\n\r\n"
  jq -n --arg status "$status" --arg message "$message" \
      '{status: $status, message: $message}'
}

function fatal() {
  status=error info "$1"
  exit 1
}

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

# Parse query string parameters
if [[ ${QUERY_STRING} ]]; then
  IFS='&' url_decode _GET_ "$QUERY_STRING"
fi

# Get the mode from query parameters
mode=${_GET_mode}
if [ "$mode" != "aliases" ]; then
  fatal "Invalid or missing mode parameter. Only 'aliases' mode is supported."
fi

# Get IP address and alias values
ipaddr=${_GET_ipaddr}
alias=${_GET_alias}

# Validate parameters
if [ -z "$ipaddr" ]; then
  fatal "Missing 'ipaddr' parameter"
fi

if [ -z "$alias" ]; then
  fatal "Missing 'alias' parameter"
fi

# Validate IP address format - only accept IPv4 addresses
if ! [[ $ipaddr =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  fatal "Invalid IP address format - must be a valid IPv4 address"
fi

# Validate the alias format
if ! [[ "$alias" =~ ^[a-zA-Z0-9.-]+$ ]]; then
  fatal "Invalid alias format. Use only letters, numbers, dots, and dashes."
fi

# Check length constraints
if [ ${#alias} -lt 1 ] || [ ${#alias} -gt 63 ]; then
  fatal "Alias must be between 1 and 63 characters"
fi

IFS=$'\n'
output=( $(/opt/logcenter/bin/zlccli set-alias "$ipaddr" "$alias" 2>&1) )
if (( $? != 0 )); then
  echo "${output[*]}" >&2
  status=error info "${output[${#output[@]}-1]#*zlccli: }"
  exit 1
fi

echo "${output[*]}" >&2
info "${output[${#output[@]}-1]#*zlccli: }"
exit 0
