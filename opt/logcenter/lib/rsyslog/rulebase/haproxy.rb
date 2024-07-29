version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

include=types/ip.rb

type=@logasap:%{
    "type": "alternative",
    "parser": [
        [   { "type": "literal", "text": "+" },
            { "type": "float", "name": "..", "format": "number" },
        ],
        { "type": "float", "name": "..", "format": "number" }
    ] }%

prefix=%[
    { "type": "@ip",        "name": "source.ip" },
    { "type": "literal",    "text": ":" },
    { "type": "number",     "name": "source.port", "format": "number", "maxval": 65535 },
    { "type": "literal",    "text": " [" },
    { "type": "char-to",    "name": "@timestamp", "extradata": "]" },
    { "type": "literal",    "text": "] " },
    { "type": "char-to",    "name": "haproxy.frontend_name", "extradata": " " },
    { "type": "literal",    "text": " " },
    { "type": "char-to",    "name": "haproxy.backend_name", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "char-to",    "name": "haproxy.server_name", "extradata": " " },
    { "type": "literal",    "text": " " },
    { "type": "float",      "name": "haproxy.http.request.time_wait_ms", "format": "number" }, 
    { "type": "literal",    "text": "/" },
    { "type": "float",      "name": "haproxy.total_waiting_time_ms", "format": "number" }, 
    { "type": "literal",    "text": "/" },
    { "type": "float",      "name": "haproxy.connection_wait_time_ms", "format": "number" }, 
    { "type": "literal",    "text": "/" },
    { "type": "float",      "name": "haproxy.http.request.time_wait_without_data_ms", "format": "number" }, 
    { "type": "literal",    "text": "/" },
    { "type": "@logasap",   "name": "haproxy.http.request.time_wait_ms" }, 
    { "type": "literal",    "text": " " },
    { "type": "float",      "name": "http.response.status_code", "format": "number" },
    { "type": "literal",    "text": " " },
    { "type": "@logasap",   "name": "http.response.bytes", "format": "number" },
    { "type": "literal",    "text": " " },
    { "type": "char-to",    "name": "haproxy.http.request.captured_cookie", "extradata": " " },
    { "type": "literal",    "text": " " },
    { "type": "char-to",    "name": "haproxy.http.response.captured_cookie", "extradata": " " },
    { "type": "literal",    "text": " " },
    { "type": "char-to",    "name": "haproxy.termination_state", "extradata": " " },
    { "type": "literal",    "text": " " },
    { "type": "number",     "name": "haproxy.connections.active", "format": "number" },
    { "type": "literal",    "text": "/" },
    { "type": "number",     "name": "haproxy.connections.frontend", "format": "number" },
    { "type": "literal",    "text": "/" },
    { "type": "number",     "name": "haproxy.connections.backend", "format": "number" },
    { "type": "literal",    "text": "/" },
    { "type": "number",     "name": "haproxy.connections.server", "format": "number" },
    { "type": "literal",    "text": "/" },
    { "type": "char-to" ,   "name": "haproxy.connections.retries", "extradata": " " },
    { "type": "literal",    "text": " " },
    { "type": "number",     "name": "haproxy.server_queue", "format": "number" },
    { "type": "literal",    "text": "/" },
    { "type": "number",     "name": "haproxy.backend_queue", "format": "number" },
    { "type": "literal",    "text": " \"" }, 
    { "type": "char-to",    "name": "http.request.method", "extradata": " " },
    { "type": "literal",    "text": " " }, 
    { "type": "char-to",    "name": "url.original", "extradata": " " },
    { "type": "literal",    "text": " " }, 
    { "type": "char-to",    "name": "http.version", "extradata": "\"" },
    { "type": "literal",    "text": "\" " }, 
    { "type": "char-to",    "name": "haproxy.connections.fc_err", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "char-to",    "name": "haproxy.connections.ssl_fc_err_hex", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "char-to",    "name": "haproxy.connections.ssl_c_err", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "char-to",    "name": "haproxy.connections.ssl_c_ca_err", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "char-to",    "name": "tls.resumed", "extradata": " " },
    { "type": "literal",    "text": " " },
    { "type": "char-to",    "name": "tls.client.server_name", "extradata": "/" },
    { "type": "literal",    "text": "/" }, 
    { "type": "char-to",    "name": "tls.version", "extradata": "/" },
    { "type": "literal",    "text": "/" }, 
    { "type": "char-to",    "name": "tls.cipher", "extradata": " " },
    { "type": "literal",    "text": " " }]%

rule=haproxy-default:%[
    ]%

rule=haproxy-others:%[
    { "type": "rest",       "name": "haproxy.others" }]%
