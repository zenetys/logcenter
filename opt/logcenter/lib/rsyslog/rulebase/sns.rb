version=2

##
## Copyright(C) 2026 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# SNS: Stormshield Network Security
# Input: $msg ($.msg)

# <BOM:\xef\xbb\xbf>id=firewall time="2026-03-25 16:03:51" fw="TE38_FW" tz=+0100 startime="2026-03-25 16:01:51" pri=5...
rule=:\xef\xbb\xbf%[ { "type": "name-value-list", "name": "sns", "assignator": "=" } ]%
rule=:%[ { "type": "name-value-list", "name": "sns", "assignator": "=" } ]%
