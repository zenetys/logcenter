##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

version=2

include=types/ip.rb

rule=:%[
    { "type": "char-to", "name": "hostname", "extradata": "/" },
    { "type": "literal", "text": "/" },
    { "type": "@ip", "name": "fromhost-ip" },
    { "type": "rest" } ]%

# If what follows the first slash cannot be parsed as an IP address,
# do not set the fromhost-ip property.
rule=:%[
    { "type": "char-to", "name": "hostname", "extradata": "/" },
    { "type": "literal", "text": "/" },
    { "type": "rest" } ]%
