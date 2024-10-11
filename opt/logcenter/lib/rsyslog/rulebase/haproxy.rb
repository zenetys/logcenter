version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

include=types/ip.rb

type=@str:%{
    "type": "string",
    "name": "..",
    "matching.mode": "lazy",
    "quoting.mode": "none",
    "quoting.escape.mode": "none"
}%

type=@intstr:%{
    "type": "string",
    "name": "..",
    "matching.mode": "lazy",
    "quoting.mode": "none",
    "quoting.escape.mode": "none",
    "matching.permitted": [
        { "class": "digit" },
        { "chars": "+-" }
    ]
}%

type=@hexstr:%{
    "type": "string",
    "name": "..",
    "matching.mode": "lazy",
    "quoting.mode": "none",
    "quoting.escape.mode": "none",
    "matching.permitted": [
        { "class": "hexdigit" },
        { "chars": "-" }
    ]
}%

type=@intplus:%{
    "type": "alternative",
    "parser": [
        {
            "type": "number",
            "name": "..",
            "format": "number",
            "priority": 100
        },
        {
            "type": "string",
            "name": "..",
            "matching.mode": "lazy",
            "quoting.mode": "none",
            "quoting.escape.mode": "none",
            "matching.permitted": [
                { "class": "digit" },
                { "chars": "+" }
            ],
            "priority": 200
        }
    ]
}%

# When there is only one captured_headers field in the log, we have no way
# to know if it corresponds to request or response headers. In such case, data
# gets stored in haproxy.http.captured_headers. It can be moved manually via
# rsyslog or elastic ingest to either haproxy.http.request.captured_headers
# or haproxy.http.response.captured_headers.
type=@caphdr_req:%[
    { "type": "literal", "text": " {" },
    { "type": "string-to", "name": "haproxy.http.captured_headers", "extradata": "} \"" },
    { "type": "literal", "text": "} \"" }
]%

type=@caphdr_req_res:%[
    { "type": "literal", "text": " {" },
    { "type": "string-to", "name": "haproxy.http.request.captured_headers", "extradata": "} {" },
    { "type": "literal", "text": "} {" },
    { "type": "string-to", "name": "haproxy.http.response.captured_headers", "extradata": "} \"" },
    { "type": "literal", "text": "} \"" }
]%

type=@caphdr_noreq_res:%[
    { "type": "literal", "text": " {} {" },
    { "type": "string-to", "name": "haproxy.http.response.captured_headers", "extradata": "} \"" },
    { "type": "literal", "text": "} \"" }
]%

type=@caphdr_req_nores:%[
    { "type": "literal", "text": " {" },
    { "type": "string-to", "name": "haproxy.http.request.captured_headers", "extradata": "} {} \"" },
    { "type": "literal", "text": "} {} \"" }
]%

type=@caphdr:%{
    "type": "alternative",
    "parser": [
        { "type": "literal", "text": " \"", "priority": 100 },
        { "type": "literal", "text": " {} \"", "priority": 110 },
        { "type": "literal", "text": " {} {} \"", "priority": 120 },
        { "type": "@caphdr_req_res", "name": ".", "priority": 200 },
        { "type": "@caphdr_noreq_res", "name": ".", "priority": 210 },
        { "type": "@caphdr_req_nores", "name": ".", "priority": 220 },
        { "type": "@caphdr_req", "name": ".", "priority": 300 }
    ]
}%

type=@req_proper:%[
    { "type": "char-to",    "name": "http.request.method", "extradata": " " },
    { "type": "literal",    "text": " " },
    { "type": "char-to",    "name": "url.original", "extradata": " " },
    { "type": "literal",    "text": " " },
    { "type": "char-to",    "name": "http.version", "extradata": "\"" }
]%

type=@req:%{
    "type": "alternative",
    "parser": [
        { "type": "literal", "name": "url.original", "text": "<BADREQ>", "priority": 100 },
        { "type": "@req_proper", "name": ".", "priority": 200 }
    ]
}%

# HTTP and HTTPS log formats
# HAPROXY_HTTP_LOG_FMT
# HAPROXY_HTTPS_LOG_FMT

type=@_http:%[
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
    { "type": "@intstr",    "name": "haproxy.http.request.time_wait_ms" },
    { "type": "literal",    "text": "/" },
    { "type": "@intstr",    "name": "haproxy.total_waiting_time_ms" },
    { "type": "literal",    "text": "/" },
    { "type": "@intstr",    "name": "haproxy.connection_wait_time_ms" },
    { "type": "literal",    "text": "/" },
    { "type": "@intstr",    "name": "haproxy.http.request.time_wait_without_data_ms" },
    { "type": "literal",    "text": "/" },
    { "type": "@intplus",   "name": "haproxy.total_time_ms" },
    { "type": "literal",    "text": " " },
    { "type": "@intstr",    "name": "http.response.status_code" },
    { "type": "literal",    "text": " " },
    { "type": "@intplus",   "name": "haproxy.bytes_read" },
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
    { "type": "@intplus",   "name": "haproxy.connections.retries", "extradata": " " },
    { "type": "literal",    "text": " " },
    { "type": "number",     "name": "haproxy.server_queue", "format": "number" },
    { "type": "literal",    "text": "/" },
    { "type": "number",     "name": "haproxy.backend_queue", "format": "number" },
    { "type": "@caphdr",    "name": "." },
]%

rule=type.http,fmt.http:%[
    { "type": "@_http",     "name": "." },
    { "type": "@req",       "name": "." },
    { "type": "literal",    "text": "\"" }
]%

rule=type.http,fmt.http_truncated:%[
    { "type": "@_http",     "name": "." },
    { "type": "char-to",    "name": "http.request.method", "extradata": " " },
    { "type": "literal",    "text": " " },
    { "type": "string",     "name": "url.original", "quoting.mode": "none", "quoting.escape.mode": "none" }
]%

rule=type.http,fmt.http_kv:%[
    { "type": "@_http",     "name": "." },
    { "type": "@req",       "name": "." },
    { "type": "literal",    "text": "\" " },
    { "type": "rest",       "name": "haproxy.others" }
]%

rule=type.http,fmt.https:%[
    { "type": "@_http",     "name": "." },
    { "type": "@req",       "name": "." },
    { "type": "literal",    "text": "\" " },
    { "type": "number",     "name": "haproxy.connections.fc_err", "format": "number" },
    { "type": "literal",    "text": "/" },
    { "type": "@hexstr",    "name": "haproxy.connections.ssl_fc_err_hex" },
    { "type": "literal",    "text": "/" },
    { "type": "@intstr",    "name": "haproxy.connections.ssl_c_err" },
    { "type": "literal",    "text": "/" },
    { "type": "@intstr",    "name": "haproxy.connections.ssl_c_ca_err" },
    { "type": "literal",    "text": "/" },
    { "type": "number",     "name": "tls.resumed", "format": "number" },
    { "type": "literal",    "text": " " },
    { "type": "char-to",    "name": "tls.client.server_name", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "char-to",    "name": "tls.version", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "@str",       "name": "tls.cipher" }
]%

rule=type.http,fmt.https_kv:%[
    { "type": "@_http",     "name": "." },
    { "type": "@req",       "name": "." },
    { "type": "literal",    "text": "\" " },
    { "type": "number",     "name": "haproxy.connections.fc_err", "format": "number" },
    { "type": "literal",    "text": "/" },
    { "type": "@hexstr",    "name": "haproxy.connections.ssl_fc_err_hex" },
    { "type": "literal",    "text": "/" },
    { "type": "@intstr",    "name": "haproxy.connections.ssl_c_err" },
    { "type": "literal",    "text": "/" },
    { "type": "@intstr",    "name": "haproxy.connections.ssl_c_ca_err" },
    { "type": "literal",    "text": "/" },
    { "type": "number",     "name": "tls.resumed", "format": "number" },
    { "type": "literal",    "text": " " },
    { "type": "char-to",    "name": "tls.client.server_name", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "char-to",    "name": "tls.version", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "@str",       "name": "tls.cipher" },
    { "type": "literal",    "text": " " },
    { "type": "rest",       "name": "haproxy.others" }
]%

# TCP log format
# HAPROXY_TCP_LOG_FMT

type=@_tcp:%[
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
    { "type": "@intstr",    "name": "haproxy.total_waiting_time_ms" },
    { "type": "literal",    "text": "/" },
    { "type": "@intstr",    "name": "haproxy.connection_wait_time_ms" },
    { "type": "literal",    "text": "/" },
    { "type": "@intplus",   "name": "haproxy.total_time_ms" },
    { "type": "literal",    "text": " " },
    { "type": "@intplus",   "name": "haproxy.bytes_read" },
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
    { "type": "@intplus",   "name": "haproxy.connections.retries", "extradata": " " },
    { "type": "literal",    "text": " " },
    { "type": "number",     "name": "haproxy.server_queue", "format": "number" },
    { "type": "literal",    "text": "/" },
    { "type": "number",     "name": "haproxy.backend_queue", "format": "number" }
]%

rule=type.tcp,fmt.tcp:%[
    { "type": "@_tcp",      "name": "." }
]%

rule=type.tcp,fmt.tcp_kv:%[
    { "type": "@_tcp",      "name": "." },
    { "type": "literal",    "text": " " },
    { "type": "rest",       "name": "haproxy.others" }
]%

# Default log format

rule=type.default,fmt.default:%[
    { "type": "literal",    "text": "Connect from " },
    { "type": "@ip",        "name": "source.ip" },
    { "type": "literal",    "text": ":" },
    { "type": "number",     "name": "source.port", "format": "number", "maxval": 65535 },
    { "type": "literal",    "text": " to " },
    { "type": "@ip",        "name": "destination.ip" },
    { "type": "literal",    "text": ":" },
    { "type": "number",     "name": "destination.port", "format": "number", "maxval": 65535 },
    { "type": "literal",    "text": " (" },
    { "type": "char-to",    "name": "haproxy.frontend_name", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "char-to",    "name": "haproxy.mode", "extradata": ")" },
    { "type": "literal",    "text": ")" }
]%

# Error log format

rule=type.error,fmt.error:%[
    { "type": "@ip",        "name": "source.ip" },
    { "type": "literal",    "text": ":" },
    { "type": "number",     "name": "source.port", "format": "number", "maxval": 65535 },
    { "type": "literal",    "text": " [" },
    { "type": "char-to",    "name": "@timestamp", "extradata": "]" },
    { "type": "literal",    "text": "] " },
    { "type": "char-to",    "name": "haproxy.frontend_name", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "char-to",    "name": "haproxy.bind_name", "extradata": ":" },
    { "type": "literal",    "text": ": " },
    { "type": "rest",       "name": "haproxy.error_message" }
]%

# Detailed error log format example from configuration manual

rule=type.error,fmt.error_detail:%[
    { "type": "@ip",        "name": "source.ip" },
    { "type": "literal",    "text": ":" },
    { "type": "number",     "name": "source.port", "format": "number", "maxval": 65535 },
    { "type": "literal",    "text": " [" },
    { "type": "char-to",    "name": "@timestamp", "extradata": "]" },
    { "type": "literal",    "text": "] " },
    { "type": "char-to",    "name": "haproxy.frontend_name", "extradata": " " },
    { "type": "literal",    "text": " " },
    { "type": "number",     "name": "haproxy.connections.active", "format": "number" },
    { "type": "literal",    "text": "/" },
    { "type": "number",     "name": "haproxy.connections.frontend", "format": "number" },
    { "type": "literal",    "text": " " },
    { "type": "number",     "name": "haproxy.connections.fc_err", "format": "number" },
    { "type": "literal",    "text": "/" },
    { "type": "@hexstr",    "name": "haproxy.connections.ssl_fc_err_hex" },
    { "type": "literal",    "text": "/" },
    { "type": "@intstr",    "name": "haproxy.connections.ssl_c_err" },
    { "type": "literal",    "text": "/" },
    { "type": "@intstr",    "name": "haproxy.connections.ssl_c_ca_err" },
    { "type": "literal",    "text": "/" },
    { "type": "number",     "name": "tls.resumed", "format": "number" },
    { "type": "literal",    "text": " " },
    { "type": "char-to",    "name": "tls.client.server_name", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "char-to",    "name": "tls.version", "extradata": "/" },
    { "type": "literal",    "text": "/" },
    { "type": "@str",       "name": "tls.cipher" }
]%

annotate=type.http:+haproxy.log.type="http"
annotate=type.tcp:+haproxy.log.type="tcp"
annotate=type.default:+haproxy.log.type="default"
annotate=type.error:+haproxy.log.type="error"

annotate=type.http:+haproxy.log.kind="traffic"
annotate=type.tcp:+haproxy.log.kind="traffic"
annotate=type.default:+haproxy.log.kind="traffic"
annotate=type.error:+haproxy.log.kind="traffic"

annotate=fmt.http_truncated:+haproxy.log.truncated="1"

# Workaround EOF after ']%' or '}%'
