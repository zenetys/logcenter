version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# Input: $rawmsg

type=@date:%{
    "type": "alternative",
    "parser": [
        { "type": "date-rfc3164" },
        { "type": "date-rfc5424" }
    ] }%

# skip after hostname field
prefix=%[
    { "type": "literal", "text": "<" },
    { "type": "number" },
    { "type": "literal", "text": ">" },
    { "type": "@date" },
    { "type": "literal", "text": " " },
    { "type": "char-to", "extradata": " " },
    { "type": "literal", "text": " " } ]%

# PaloAlto logs:
# <13>Mar  6 14:17:21 FW-PANOS 1,2024/03/06 14:01:53,445566778899,TRAFFIC,drop,...
rule=:%[
    { "type": "literal", "text": "1," },
    { "type": "number" },
    { "type": "literal", "text": "/" },
    { "type": "number" },
    { "type": "literal", "text": "/" },
    { "type": "number" },
    { "type": "literal", "text": " " },
    { "type": "number" },
    { "type": "literal", "text": ":" },
    { "type": "number" },
    { "type": "literal", "text": ":" },
    { "type": "number" },
    { "type": "literal", "text": "," },
    { "type": "rest" } ]%

# <30>Apr 22 17:53:24 localhost last message repeated 2 times
rule=:%[
    { "type": "literal", "text": "last message repeated " },
    { "type": "number" },
    { "type": "literal", "text": " times" } ]%
