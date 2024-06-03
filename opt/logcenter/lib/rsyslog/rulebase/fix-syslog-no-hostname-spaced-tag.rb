version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# Input: $rawmsg

type=@date:%{
    "type": "alternative",
    "parser": [
        { "type": "date-rfc3164", "name": ".." },
        { "type": "date-rfc5424", "name": ".." }
    ] }%

# skip after date field
prefix=%[
    { "type": "literal", "text": "<" },
    { "type": "number" },
    { "type": "literal", "text": ">" },
    { "type": "@date", "name": "date" },
    { "type": "literal", "text": " " } ]%

# <142>May 23 15:43:36 Oracle Audit[24248796]: LENGTH : ...
# <142>May 23 15:48:22 Oracle Unified Audit[63439104]: LENGTH:...
rule=:%[
    { "type": "literal", "text": "Oracle Audit", "name": "app-name" },
    { "type": "literal", "text": "[" },
    { "type": "number", "name": "procid" },
    { "type": "literal", "text": "]: " },
    { "type": "rest", "name": "msg" } ]%
rule=:%[
    { "type": "literal", "text": "Oracle Unified Audit", "name": "app-name" },
    { "type": "literal", "text": "[" },
    { "type": "number", "name": "procid" },
    { "type": "literal", "text": "]: " },
    { "type": "rest", "name": "msg" } ]%
