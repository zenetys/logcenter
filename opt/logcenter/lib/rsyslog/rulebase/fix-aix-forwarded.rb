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

# AIX forwarded logs, skip after hostname
prefix=%[
    { "type": "literal", "text": "<" },
    { "type": "number" },
    { "type": "literal", "text": ">" },
    { "type": "@date" },
    { "type": "literal", "text": " " },
    { "type": "literal", "text": "Message forwarded from " },
    { "type": "char-to", "extradata": ":", "name": "hostname" },
    { "type": "literal", "text": ": " } ]%

# <142>Jan 16 14:03:54 Message forwarded from srv-ora-01: Oracle Audit[1382197]: LENGTH:...
rule=:%[
    { "type": "char-to", "extradata": "[", "name": "app-name" },
    { "type": "literal", "text": "[" },
    { "type": "char-to", "extradata": "]", "name": "procid" },
    { "type": "literal", "text": "]: " },
    { "type": "rest", "name": "msg" } ]%

# <142>Jan 16 14:03:54 Message forwarded from srv-ora-01: unix: The pivilege command...
rule=noprocid:%[
    { "type": "string", "quoting.mode": "none",
          "matching.permitted": [ {"class":"alnum"}, {"chars":"-_@#~|/\\().;!,?<>{}"} ],
          "matching.mode": "lazy", "name": "app-name" },
    { "type": "literal", "text": ": " },
    { "type": "rest", "name": "msg" } ]%

# <174>Mar 21 11:21:44 Message forwarded from srv-ora-01: last message repeated 2 times
rule=noprocid,noappname:%[
    { "type": "rest", "name": "msg" } ]%
