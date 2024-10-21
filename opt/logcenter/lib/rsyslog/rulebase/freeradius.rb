version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# **Auth-Access-Accept** ...
rule=freeradius.auth,freeradius.auth.accept:%[
    { "type": "literal", "text": "**" },
    { "type": "literal", "name": "freeradius.type", "text": "Auth" },
    { "type": "literal", "text": "-" },
    { "type": "literal", "name": "freeradius.action", "text": "Access-Accept" },
    { "type": "literal", "text": "** " },
    { "type": "rest", "name": "freeradius.request.pairs" }
]%

# **Auth-Access-Reject** ...
rule=freeradius.auth,freeradius.auth.reject:%[
    { "type": "literal", "text": "**" },
    { "type": "literal", "name": "freeradius.type", "text": "Auth" },
    { "type": "literal", "text": "-" },
    { "type": "literal", "name": "freeradius.action", "text": "Access-Reject" },
    { "type": "literal", "text": "** " },
    { "type": "rest", "name": "freeradius.request.pairs" }
]%

annotate=freeradius.auth:+event.kind="event"
annotate=freeradius.auth:+event.category="authentication,network"
annotate=freeradius.auth.accept:+event.type="info,allowed"
annotate=freeradius.auth.reject:+event.type="info,denied"
annotate=freeradius.auth.accept:+event.outcome="success"
annotate=freeradius.auth.reject:+event.outcome="failure"

# Workaround EOF after ']%' or '}%'
