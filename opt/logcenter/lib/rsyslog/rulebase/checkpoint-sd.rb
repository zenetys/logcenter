version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# Input: $structured-data

# [action:"Allow"; flags:"400644"; ifdir:"inbound"; ...; service_id:"ptos_avaya"; src:"11.22.33.77"; ]

rule=:%[
    { "type": "literal", "text": "[" },
    { "type": "checkpoint-lea", "terminator": "]", "name": "checkpoint" },
    { "type": "literal", "text": "]" }
]%

# Workaround EOF after ']%' or '}%'
