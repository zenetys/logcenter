version=2

include=types/ip.rb
include=types/user.rb

# 10.109.21.42 - - [17/Jun/2024:09:54:42 +0200] "POST /path/to/script HTTP/1.1" 200 32326
# 10.109.21.42 - - [17/Jun/2024:09:54:42 +0200] "POST /path/to/script?query=string&something=else HTTP/1.1" 200 32326
# 10.109.21.42 - acme\someone [17/Jun/2024:09:54:42 +0200] "GET /path/to/script HTTP/1.1" 200 -
rule=w3c,w3c.access,w3c.access.common:%[
    { "type": "@ip", "name": "source.ip" },
    { "type": "whitespace" },
    { "type": "char-to", "name": "w3c.identity", "extradata": " " },
    { "type": "whitespace" },
    { "type": "@user", "name": "." },
    { "type": "whitespace" },
    { "type": "literal", "text": "[" },
    { "type": "char-to", "name": "w3c.timestamp_raw", "extradata": "]" },
    { "type": "literal", "text": "]" },
    { "type": "whitespace" },
    { "type": "literal", "text": "\"" },
    { "type": "char-to", "name": "http.request.method", "extradata": " " },
    { "type": "whitespace" },
    { "type": "char-to", "name": "url.original", "extradata": " " },
    { "type": "whitespace" },
    { "type": "literal", "text": "HTTP/" },
    { "type": "char-to", "name": "http.version", "extradata": "\"" },
    { "type": "literal", "text": "\"" },
    { "type": "whitespace" },
    { "type": "number", "name": "http.response.status_code", "format": "number" },
    { "type": "whitespace" },
    { "type": "word", "name": "http.response.body.bytes" },
    { "type": "rest" } ]%

# 10.109.21.42 - - 17/06/2024 08:07:42.338 122 "GET /path/to/something HTTP/1.1" 200 206
rule=w3c,w3c.access,w3c.access.common_custom_date:%[
    { "type": "@ip", "name": "source.ip" },
    { "type": "whitespace" },
    { "type": "char-to", "name": "w3c.identity", "extradata": " " },
    { "type": "whitespace" },
    { "type": "@user", "name": "." },
    { "type": "whitespace" },
    { "type": "char-to", "name": "w3c.timestamp_date", "extradata": " " },
    { "type": "whitespace" },
    { "type": "char-to", "name": "w3c.timestamp_time", "extradata": " " },
    { "type": "whitespace" },
    { "type": "number", "name": "w3c.time_taken_ms", "format": "number" },
    { "type": "whitespace" },
    { "type": "literal", "text": "\"" },
    { "type": "char-to", "name": "http.request.method", "extradata": " " },
    { "type": "whitespace" },
    { "type": "char-to", "name": "url.original", "extradata": " " },
    { "type": "whitespace" },
    { "type": "literal", "text": "HTTP/" },
    { "type": "char-to", "name": "http.version", "extradata": "\"" },
    { "type": "literal", "text": "\"" },
    { "type": "whitespace" },
    { "type": "number", "name": "http.response.status_code", "format": "number" },
    { "type": "whitespace" },
    { "type": "word", "name": "http.response.body.bytes", "extradata": " " },
    { "type": "rest" } ]%

annotate=w3c:+event.category="web"
annotate=w3c.access:+service.name="access"
