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

# <30>Apr 22 17:53:24 last message repeated 2 times
rule=:%[
    { "type": "literal", "text": "last message repeated " },
    { "type": "number" },
    { "type": "literal", "text": " times" } ]%
