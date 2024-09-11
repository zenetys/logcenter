version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

include=types/ip.rb
include=types/user.rb

type=@client_source_ip1:%[
    { "type": "literal", "text": "-/" },
    { "type": "@ip", "name": "source.ip" }
]%

type=@client_source_ip2:%[
    { "type": "@ip", "name": "client.ip" },
    { "type": "literal", "text": "/" },
    { "type": "@ip", "name": "source.ip" }
]%

type=@client_source_ip3:%{
    "type": "@ip",
    "name": "source.ip"
}%

type=@client_source_ip:%{
    "type": "alternative",
    "parser": [
        { "type": "@client_source_ip1", "name": ".", "priority": 100 },
        { "type": "@client_source_ip2", "name": ".", "priority": 200 },
        { "type": "@client_source_ip3", "name": ".", "priority": 300 }
    ]
}%

# access log
prefix=%[
    { "type": "float", "name": "@timestamp", "format": "number" },
    { "type": "whitespace" },
    { "type": "number", "name": "squid.response_time_ms", "format": "number" },
    { "type": "whitespace" },
    { "type": "@client_source_ip", "name": "." },
    { "type": "whitespace" },
    { "type": "char-to", "name": "squid.request_status", "extradata": "/" },
    { "type": "literal", "text": "/" },
    { "type": "number", "name": "http.response.status_code", "format": "number" },
    { "type": "whitespace" },
    { "type": "number", "name": "http.response.bytes", "format": "number" },
    { "type": "whitespace" },
    { "type": "char-to", "name": "http.request.method", "extradata": " " },
    { "type": "whitespace" },
    { "type": "char-to", "name": "url.original", "extradata": " " },
    { "type": "whitespace" },
    { "type": "@user", "name": "." },
    { "type": "whitespace" },
    { "type": "char-to", "name": "squid.hierarchy_status", "extradata": "/" },
    { "type": "literal", "text": "/" },
    { "type": "char-to", "name": "squid.last_peer", "extradata": " " },
    { "type": "whitespace" },
    { "type": "word", "name": "http.response.mime_type" }
]%

# 1726047659.822      0 10.50.1.11 NONE_NONE/000 0 - error:transaction-end-before-headers - HIER_NONE/- -
# 1725627417.284    118 10.50.1.11 TCP_MISS/302 688 GET http://www.debian.org/ - ORIGINAL_DST/194.177.211.216 text/html
rule=squid,squid.access:%[]%

# 1725631953.393     75 10.50.1.11 TCP_TUNNEL/200 20296 CONNECT www.debian.org:443 - ORIGINAL_DST/130.89.148.77 - squid.ssl.bump_mode=splice squid.ssl.sni=www.debian.org
rule=squid,squid.access:%[
    { "type": "whitespace" },
    { "type": "name-value-list", "name": "." }
]%

annotate=squid.access:+event.provider="access"
annotate=squid.access:+event.category="network,web"
