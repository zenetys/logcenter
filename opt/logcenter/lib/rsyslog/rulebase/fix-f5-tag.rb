version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# Input: $msg

# F5 logs after severity text put as syslog tag
# apmd[21614]: 01490007:6: ...
# tmm3[19438]: Rule /Comm...

rule=:%[
    { "type": "literal", "text": " " },
    { "type": "char-to", "extradata": "[", "name": "app-name" },
    { "type": "literal", "text": "[" },
    { "type": "char-to", "extradata": "]", "name": "procid" },
    { "type": "literal", "text": "]: " },
    { "type": "rest", "name": "msg" } ]%

# not seen so far
rule=noprocid:%[
    { "type": "literal", "text": " " },
    { "type": "string", "quoting.mode": "none",
          "matching.permitted": [ {"class":"alnum"}, {"chars":"-_@#~|/\\().;!,?<>{}"} ],
          "matching.mode": "lazy", "name": "app-name" },
    { "type": "literal", "text": ": " },
    { "type": "rest", "name": "msg" } ]%

# not seen so far, catchall
rule=noprocid,noappname:%[
    { "type": "literal", "text": " " },
    { "type": "rest", "name": "msg" } ]%
