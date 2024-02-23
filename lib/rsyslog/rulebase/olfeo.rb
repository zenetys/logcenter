version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

include=types/ip.rb
include=types/user.rb

# $Req-Answer-Reason$
# 200 granted
# 201 granted-quota
# 202 granted-time
# 203 overstepped-no-password
# 204 overstepped-password
# 401 quota-page
# 402 blocked-time
# 403 blocked
# 405 charter-page

# $Matched-Policy-Id$
# -2 connection (ACL)
# -3 access (ACL)
# -4 content (ACL)
# -5 preview (ACL)
# >0 policy

# $Req-Status$
# 0 unknown
# 1 allowed
# 2 blocked
# 3 redirected

# standard format
# $ip$ - $Username$ [$date$] "$Method$ $Url$ HTTP/1.1" $Req-Answer-Reason$ - - $Category-Id$ $category$
#
rule=:%[
   { "type": "@ip", "name": "source.ip" },
    { "type": "whitespace" },
    { "type": "literal", "text": "-" },
    { "type": "whitespace" },
    { "type": "@user", "name": "." },
    { "type": "whitespace" },
    { "type": "literal", "text": "[" },
    { "type": "char-to", "extradata": "]", "name": "date_utc" },
    { "type": "literal", "text": "] \"" },
    { "type": "char-to", "extradata": " ", "name": "http.request.method" },
    { "type": "whitespace" },
    { "type": "char-to", "extradata": " ", "name": "url.original" },
    { "type": "whitespace" },
    { "type": "literal", "text": "HTTP/1.1\"" },
    { "type": "whitespace" },
    { "type": "number", "format": "number", "name": "answer_reason" },
    { "type": "whitespace" },
    { "type": "literal", "text": "-" },
    { "type": "whitespace" },
    { "type": "literal", "text": "-" },
    { "type": "whitespace" },
    { "type": "char-to", "extradata": " ", "name": "category_id" },
    { "type": "whitespace" },
    { "type": "rest", "name": "category_label" } ]%

# fmt2 format
# $ip$ - $Username$ [$date$] "$Method$ $Url$ HTTP/1.1" $Req-Answer-Reason$ - - $Category-Id$ $category$ \
#   - - $Timestamp$ $Proxy-Id$ $Matched-Policy-Id$ $Req-Status$ $Size$ - - $Virus-Name$
#
rule=:%[
    { "type": "literal", "text": "fmt2: " },
    { "type": "@ip", "name": "source.ip" },
    { "type": "whitespace" },
    { "type": "literal", "text": "-" },
    { "type": "whitespace" },
    { "type": "@user", "name": "." },
    { "type": "whitespace" },
    { "type": "literal", "text": "[" },
    { "type": "char-to", "extradata": "]", "name": "date_utc" },
    { "type": "literal", "text": "] \"" },
    { "type": "char-to", "extradata": " ", "name": "http.request.method" },
    { "type": "whitespace" },
    { "type": "char-to", "extradata": " ", "name": "url.original" },
    { "type": "whitespace" },
    { "type": "literal", "text": "HTTP/1.1\"" },
    { "type": "whitespace" },
    { "type": "number", "format": "number", "name": "answer_reason" },
    { "type": "whitespace" },
    { "type": "literal", "text": "-" },
    { "type": "whitespace" },
    { "type": "literal", "text": "-" },
    { "type": "whitespace" },
    { "type": "char-to", "extradata": " ", "name": "category_id" },
    { "type": "whitespace" },
    { "type": "string-to", "extradata": " - - ", "name": "category_label" },
    { "type": "literal", "text": " - - " },
    { "type": "number", "format": "number", "name": "timestamp" },
    { "type": "whitespace" },
    { "type": "char-to", "extradata": " ", "name": "proxy_id" },
    { "type": "whitespace" },
    { "type": "char-to", "extradata": " ", "name": "policy_id" },
    { "type": "whitespace" },
    { "type": "number", "format": "number", "name": "request_status" },
    { "type": "whitespace" },
    { "type": "number", "format": "number", "name": "size" },
    { "type": "literal", "text": " - - " },
    { "type": "rest", "name": "virus_name" } ]%
