version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

type=@blank:%{
    "type": "alternative",
    "parser": [
        { "type": "literal", "text": "\t", "priority": 100 },
        { "type": "literal", "text": " ", "priority": 200 }
    ]
}%

# <blank>at [Source: REDACTED (`StreamReadFeature.INCLUDE_SOURCE_IN_LOCATION` disabled); line: 1, column: 1]$
rule=:%[
    { "type": "@blank" },
    { "type": "literal", "text": "at [Source: " },
    { "type": "char-to", "extradata": ";" },
    { "type": "literal", "text": "; line: " },
    { "type": "number" },
    { "type": "literal", "text": ", column: " },
    { "type": "number" },
    { "type": "literal", "text": "]" }
]%

# <blank>at org.redacted.protocol.oauth.OAuthService$redactedinvoker$redactedBinding_1fb0e5777b2f3e9a4251d283c18c67ce996774b7.invoke(Unknown Source)","unparsed-data":"Unknown Source)
rule=:%[
    { "type": "@blank" },
    { "type": "literal", "text": "at " },
    { "type": "char-to", "extradata": "(" },
    { "type": "literal", "text": "(Unknown Source)" }
]%

# <blank>at org.jboss.resteasy.reactive.server.handlers.InvocationHandler.handle(InvocationHandler.java:29)
rule=:%[
    { "type": "@blank" },
    { "type": "literal", "text": "at " },
    { "type": "char-to", "extradata": "(" },
    { "type": "literal", "text": "(" },
    { "type": "char-to", "extradata": ":" },
    { "type": "literal", "text": ":" },
    { "type": "number" },
    { "type": "literal", "text": ")" }
]%

# Caused by: java.lang.ArithmeticException: The denominator must not be zero
rule=:%[
    { "type": "literal", "text": "Caused by: " },
    { "type": "char-to", "extradata": ":" },
    { "type": "literal", "text": ": " },
    { "type": "rest" }
]%

# Caused by: java.lang.NullPointerException
rule=:%[
    { "type": "literal", "text": "Caused by: " },
    { "type": "rest" }
]%

# <blank>... 16 more
rule=:%[
    { "type": "@blank" },
    { "type": "literal", "text": "... " },
    { "type": "number" },
    { "type": "literal", "text": " more" }
]%

# Workaround EOF after ']%' or '}%'
