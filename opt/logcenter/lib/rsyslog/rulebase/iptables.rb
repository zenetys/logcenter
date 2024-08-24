version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

type=@iptables_without_prefix:%[
    { "type": "v2-iptables", "name": "iptables.raw" } ]%

type=@iptables_with_prefix:%[
    { "type": "char-to", "name": "iptables.prefix", "extradata": " " },
    { "type": "whitespace" },
    { "type": "v2-iptables", "name": "iptables.raw" } ]%

type=@iptables:%{
    "type": "alternative",
    "parser": [
        { "type": "@iptables_without_prefix", "name": ".", "priority": 100 },
        { "type": "@iptables_with_prefix", "name": ".", "priority": 200 }
    ] }%

# DROP(84,flt,INTERNET) IN=ens18 OUT= MAC=12:34:56:78:9a:bc:12:34:56:78:9a:bc:08:00 SRC=1.2.3.4 DST=5.6.7.8 LEN=44 TOS=0x00 PREC=0x00 TTL=249 ID=54321 PROTO=TCP SPT=49701 DPT=52931 WINDOW=65535 RES=0x00 SYN URGP=0
rule=:%[
    { "type": "@iptables", "name": ".", "extradata": " " } ]%

# ACCEPT(34,flt,RELATED) IN=ens18 OUT= MAC=12:34:56:78:9a:bc:12:34:56:78:9a:bc:08:00 SRC=1.2.3.4 DST=5.6.7.8 LEN=68 TOS=0x18 PREC=0xC0 TTL=59 ID=7083 PROTO=ICMP TYPE=3 CODE=2 [SRC=5.6.7.8 DST=1.2.3.4 LEN=40 TOS=0x18 PREC=0x20 TTL=250 ID=8 PROTO=112 ] 
rule=:%[
    { "type": "char-to", "name": "iptables.left", "extradata": "[" },
    { "type": "literal", "text": "[" },
    { "type": "char-to", "name": "iptables.related", "extradata": "]" },
    { "type": "literal", "text": "] " },
    { "type": "rest", "name": "iptables.right" } ]%
