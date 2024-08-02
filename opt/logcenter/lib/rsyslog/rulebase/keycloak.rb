version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

rule=keycloak.event:%[
    { "type": "char-to", "name": "keycloak.date", "extradata": " " }, { "type": "literal", "text": " " },
    { "type": "char-to", "name": "keycloak.time", "extradata": " " }, { "type": "literal", "text": " " },
    { "type": "char-to", "name": "log.level", "extradata": " " }, { "type": "whitespace" },
    { "type": "literal", "text": "[" },
    { "type": "char-to", "name": "event.module", "extradata": "]" }, { "type": "literal", "text": "] " },
    { "type": "literal", "text": "(" },
    { "type": "char-to", "name": "process.thread.name", "extradata": ")" }, { "type": "literal", "text": ") " },
    { "type": "rest", "name": "keycloak.attributes" } ]%
