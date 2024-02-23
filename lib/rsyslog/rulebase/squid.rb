##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

version=2

include=types/ip.rb
include=types/user.rb

type=@client_source_ip1:%[
    { "type": "literal", "text": "-/" },
    { "type": "@ip", "name": "source.ip" } ]%

type=@client_source_ip2:%[
    { "type": "@ip", "name": "client.ip" },
    { "type": "literal", "text": "/" },
    { "type": "@ip", "name": "source.ip" } ]%

type=@client_source_ip3:%[
    { "type": "@ip", "name": "source.ip" } ]%

type=@client_source_ip:%{
    "type": "alternative",
    "parser": [
        { "type": "@client_source_ip1", "name": ".", "priority": 100 },
        { "type": "@client_source_ip2", "name": ".", "priority": 200 },
        { "type": "@client_source_ip3", "name": ".", "priority": 300 }
    ] }%

prefix=%[
    { "type": "float",      "name": "@timestamp", "format": "number" },
    { "type": "whitespace" },
    { "type": "number",     "name": "squid.response_time_ms", "format": "number" },
    { "type": "whitespace" },
    { "type": "@client_source_ip", "name": "." },
    { "type": "whitespace" },
    { "type": "char-to",    "name": "squid.request_status", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "number",     "name": "http.response.status_code", "format": "number" },
    { "type": "whitespace" },
    { "type": "number",     "name": "http.response.bytes", "format": "number" },
    { "type": "whitespace" } ]%

rule=squid,squid.access:%[
    { "type": "char-to",    "name": "http.request.method", "extradata": " " },
    { "type": "whitespace" },
    { "type": "char-to",    "name": "url.original", "extradata": " " },
    { "type": "whitespace" },
    { "type": "@user",      "name": "." },
    { "type": "whitespace" },
    { "type": "char-to",    "name": "squid.hierarchy_status", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "char-to",    "name": "squid.last_peer", "extradata": " " },
    { "type": "whitespace" },
    { "type": "word",       "name": "http.response.mime_type" },
    { "type": "rest" } ]%

annotate=squid:+service.type="squid"
annotate=squid.access:+service.name="access"
annotate=squid.access:+event.category="network"
