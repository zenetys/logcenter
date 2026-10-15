version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# Input: $structured-data

# [zlc@0 srcIp="10.1.1.120" srcHost="host120" clientId="" zlcHop="1" timeReceived="2026-10-01T12:24:13.011291+02:00"]
# [zlc@0 srcIp="10.1.1.120" srcHost="host120" clientId="" zlcHop="1" timeReceived="2026-10-01T12:24:13.011291+02:00"][... more ...]
rule=:%[
    { "type": "literal", "text": "[" },
    { "type": "char-to", "extradata": " " },
    { "type": "literal", "text": " " },
    { "type": "name-value-list", "name": "." },
    { "type": "literal", "text": "]" },
    { "type": "rest" }
]%

# Workaround EOF after ']%' or '}%'
