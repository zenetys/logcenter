version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# Input: $rawmsg or $msg ($.msg)

include=types/percent.rb

# Use legacy syntax because we could not make litteral "%" (char 0x25)
# recognized with the JSON syntax (tried "\\x25", "%%").
prefix=%cisco.unparsed_header:char-sep:\x25%\x25

type=@cisco_tag_word:%{
    "type": "string",
    "matching.permitted": [ {"chars": "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"} ],
    "matching.mode": "lazy",
    "name": ".."
}%

# SPANTREE-7-ROOTCHANGE: ...
# LINEPROTO-5-UPDOWN: ...
rule=:%[
    { "type": "@cisco_tag_word", "name": "cisco.facility" },
    { "type": "literal", "text": "-" },
    { "type": "number", "name": "cisco.severity", "maxval": 7, "format": "number" },
    { "type": "literal", "text": "-" },
    { "type": "@cisco_tag_word", "name": "cisco.mnemonic" },
    { "type": "literal", "text": ":" },
    { "type": "whitespace" },
    { "type": "rest", "name": "cisco.message" } ]%

# DIAG-SP-6-RUN_MINIMUM: ...
rule=:%[
    { "type": "@cisco_tag_word", "name": "cisco.facility" },
    { "type": "literal", "text": "-" },
    { "type": "@cisco_tag_word", "name": "cisco.source" },
    { "type": "literal", "text": "-" },
    { "type": "number", "name": "cisco.severity", "maxval": 7, "format": "number" },
    { "type": "literal", "text": "-" },
    { "type": "@cisco_tag_word", "name": "cisco.mnemonic" },
    { "type": "literal", "text": ":" },
    { "type": "whitespace" },
    { "type": "rest", "name": "cisco.message" } ]%

# DIAG-SP-STDBY-6-RUN_MINIMUM: ...
rule=:%[
    { "type": "@cisco_tag_word", "name": "cisco.facility" },
    { "type": "literal", "text": "-" },
    { "type": "@cisco_tag_word", "name": "cisco.source" },
    { "type": "literal", "text": "-" },
    { "type": "@cisco_tag_word", "name": "cisco.state" },
    { "type": "literal", "text": "-" },
    { "type": "number", "name": "cisco.severity", "maxval": 7, "format": "number" },
    { "type": "literal", "text": "-" },
    { "type": "@cisco_tag_word", "name": "cisco.mnemonic" },
    { "type": "literal", "text": ":" },
    { "type": "whitespace" },
    { "type": "rest", "name": "cisco.message" } ]%
