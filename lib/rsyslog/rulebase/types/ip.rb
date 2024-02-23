version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

include=types/percent.rb

type=@ip:%{
    "type": "alternative",
    "parser": [
        { "type": "ipv4", "name": ".." },
        { "type": "ipv6", "name": ".." }
    ] }%

# Standard field type ipv6 does not recognize well some IPv6
# representations (seen with Cisco logs). This may be used as
# an alternative. The lazy mode allow to stop for instance on
# a colon ":" character, but may cause incorrect matching if
# there is not a literal to match after.
type=@ip2:%{
    "type": "alternative",
    "parser": [
        { "type": "ipv4", "name": ".." },
        {
            "type": "string", "name": "..",
            "quoting.mode": "none",
            "matching.mode": "lazy",
            "matching.permitted": [
                { "class": "hexdigit" },
                { "chars": ":" }
            ]
        }
    ] }%

type=@ip_win_csv1:%[
        { "type": "@ip2", "name": ".." } ]%

type=@ip_win_csv2:%[
        { "type": "@ip2", "name": ".." },
        { "type": "@percent" },
        { "type": "char-to", "extradata": "," } ]%

type=@ip_win_csv:%{
    "type": "alternative",
    "parser": [
        { "type": "@ip_win_csv2", "name": "..", "priority": 0 },
        { "type": "@ip_win_csv1", "name": ".." },
        { "type": "literal", "name": "..", "text": "", "priority": 65535 }
    ] }%
