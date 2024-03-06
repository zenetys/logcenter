version=2

##
## Copyright(C) 2023 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# Input: $rawmsg

# <142>Dec  6 23:04:36 2023 10.109.21.206 <10.109.21.206 C8:A5:DA:E3:21:87> snmp[5403]: ...
# <142>Dec  6 23:04:36 2023 10.109.21.206 <10.109.21.206 C8:A5:DA:E3:21:87> dnsmasq[10711]: ...

type=@fix_aruba_ap_before_tag:%[
    { "type": "literal", "text": "<" },
    { "type": "ipv4", "name": "ip" },
    { "type": "literal", "text": " " },
    { "type": "mac48", "name": "mac" },
    { "type": "literal", "text": ">" } ]%

rule=:%[
    { "type": "literal", "text": "<" },
    { "type": "number" },
    { "type": "literal", "text": ">" },
    { "type": "date-rfc3164" },
    { "type": "literal", "text": " " },
    { "type": "number" },
    { "type": "literal", "text": " " },
    { "type": "word" },
    { "type": "literal", "text": " " },
    { "type": "@fix_aruba_ap_before_tag", "name": "before-tag" },
    { "type": "literal", "text": " " },
    { "type": "char-to", "extradata": "[", "name": "app-name" },
    { "type": "literal", "text": "[" },
    { "type": "number", "name": "procid" },
    { "type": "literal", "text": "]" },
    { "type": "literal", "text": ": " },
    { "type": "rest", "name": "msg" } ]%
