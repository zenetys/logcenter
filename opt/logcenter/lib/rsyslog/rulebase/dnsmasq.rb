version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# Input: $msg ($.msg)

include=types/ip.rb

# log-queries=extra header
# 14666331 10.109.21.34/57020
# 14666331 10.109.21.34/57020
# 14666331 10.109.21.34/57020
# 14666331 10.109.21.34/57020
prefix=%[
    { "type": "char-to", "name": "dnsmasq.serial", "extradata": " " },
    { "type": "whitespace" },
    { "type": "@ip", "name": "source.ip" },
    { "type": "literal", "text": "/" },
    { "type": "number", "name": "source.port", "format": "number" },
    { "type": "whitespace" } ]%

# 15512656 10.109.21.34/50736 query[type=65] 4.courier-push-apple.com.akadns.net from 10.109.21.34
rule=dnsmasq.dns:%[
    { "type": "literal", "name": "dnsmasq.context", "text": "query" },
    { "type": "literal", "text": "[type=" },
    { "type": "char-to", "name": "dnsmasq.query_type", "extradata": "]" },
    { "type": "literal", "text": "] " },
    { "type": "char-to", "name": "dns.question.name", "extradata": " " },
    { "type": "literal", "text": " from " },
    { "type": "rest" } ]%

# 14666331 10.109.21.34/57020 query[A] au.download.windowsupdate.com from 10.109.21.34
rule=dnsmasq.dns:%[
    { "type": "literal", "name": "dnsmasq.context", "text": "query" },
    { "type": "literal", "text": "[" },
    { "type": "char-to", "name": "dns.question.type", "extradata": "]" },
    { "type": "literal", "text": "] " },
    { "type": "char-to", "name": "dns.question.name", "extradata": " " },
    { "type": "literal", "text": " from " },
    { "type": "rest" } ]%

# 14666331 10.109.21.34/57020 forwarded au.download.windowsupdate.com to 1.1.1.1
rule=dnsmasq.dns:%[
    { "type": "literal", "name": "dnsmasq.context", "text": "forwarded" },
    { "type": "literal", "text": " " },
    { "type": "char-to", "name": "dns.question.name", "extradata": " " },
    { "type": "literal", "text": " to " },
    { "type": "@ip", "name": "dnsmasq.forwarded_ip" } ]%

# 14666331 10.109.21.34/57020 reply a767.dspw65.akamai.net is 23.72.249.149
rule=dnsmasq.dns:%[
    { "type": "char-to", "name": "dnsmasq.context", "extradata": " " },
    { "type": "literal", "text": " " },
    { "type": "char-to", "name": "dns.question.name", "extradata": " " },
    { "type": "literal", "text": " is " },
    { "type": "@ip", "name": "dns.resolved_ip" } ]%

# 14666331 10.109.21.34/57020 reply au.download.windowsupdate.com is <CNAME>
rule=dnsmasq.dns:%[
    { "type": "char-to", "name": "dnsmasq.context", "extradata": " " },
    { "type": "literal", "text": " " },
    { "type": "char-to", "name": "dns.question.name", "extradata": " " },
    { "type": "literal", "text": " is " },
    { "type": "rest", "name": "dnsmasq.answer" } ]%

annotate=dnsmasq.dns:+dnsmasq.service="dns"
