version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# base types

#type=@dom_text:%{
#    "type": "string",
#    "name": "domain",
#    "matching.mode": "lazy",
#    "quoting.mode": "none",
#    "quoting.escape.mode": "none",
#    "matching.permitted": [
#        { "class": "alnum" },
#        { "chars": ".-" }
#    ]
#}%

# The standard ipv6 type require that it be followed by whitespace or
# end-of-string, hence we cannot use use between brackets [<ipv6>].
type=@dom_ipv6:%[
    { "type": "literal", "text": "[" },
    {
        "type": "string",
        "name": "..",
        "quoting.mode": "none",
        "quoting.escape.mode": "none",
        "matching.mode": "lazy",
        "matching.permitted": [
            { "class": "hexdigit" },
            { "chars": ":" }
        ]
    },
    { "type": "literal", "text": "]" }
]%

# strict rfc3986
#type=@dom:%{
#        "type": "alternative",
#        "parser": [
#{ "type": "@dom_text", "name": ".", "priority": 60010 },
#{ "type": "ipv4", "name": "domain", "priority": 60020 },
#{ "type": "@dom_ipv6", "name": ".", "priority": 60030 }
#        ]
#}%
# more tolerant but may produce empty domain variables
#type=@dom:%{
#    "type": "char-sep",
#    "name": "domain",
#    "extradata": ":/?#"
#}%

type=@dom:%{
        "type": "alternative",
        "parser": [
{
    "type": "@dom_ipv6",
    "name": "domain",
    "priority": 60010
},
{
    "type": "char-sep",
    "name": "domain",
    "extradata": ":/?#",
    "priority": 65535
}
        ]
}%

type=@port:%{
    "type": "number",
    "name": "port",
    "format": "number",
    "maxval": 65535
}%

# strict rfc3986
#type=@path:%{
#    "type": "string",
#    "name": "path",
#    "matching.mode": "lazy",
#    "quoting.mode": "none",
#    "quoting.escape.mode": "none",
#    "matching.permitted": [
#        { "class": "alnum" },
#        { "chars": "/%%:@-._~!$&'()*+,;=" }
#    ]
#}%
# more tolerant but may produce empty path variables
type=@path:%{
        "type": "alternative",
        "parser": [
{
    "type": "char-sep",
    "name": "path",
    "extradata": "?#",
    "priority": 60010
},
{
    "type": "string",
    "name": "path",
    "quoting.mode": "none",
    "quoting.escape.mode": "none",
    "priority": 60020
}
        ]
}%

# strict rfc3986
#type=@query:%{
#    "type": "string",
#    "name": "query",
#    "matching.mode": "lazy",
#    "quoting.mode": "none",
#    "quoting.escape.mode": "none",
#    "matching.permitted": [
#        { "class": "alnum" },
#        { "chars": "/%%:@-._~!$&'()*+,;=?" }
#    ]
#}%
# more tolerant but may produce empty query variables
type=@query:%{
        "type": "alternative",
        "parser": [
{
    "type": "char-sep",
    "name": "query",
    "extradata": "#",
    "priority": 60010
},
{
    "type": "string",
    "name": "query",
    "quoting.mode": "none",
    "quoting.escape.mode": "none",
    "priority": 60020
}
        ]
}%

# strict rfc3986
#type=@frag:%{
#    "type": "string",
#    "name": "fragment",
#    "matching.mode": "lazy",
#    "quoting.mode": "none",
#    "quoting.escape.mode": "none",
#    "matching.permitted": [
#        { "class": "alnum" },
#        { "chars": "/%%:@-._~!$&'()*+,;=?" }
#    ]
#}%
# more tolerant
#type=@frag:%{
#    "type": "string",
#    "name": "fragment",
#    "quoting.mode": "none",
#    "quoting.escape.mode": "none"
#}%
# more tolerant allowing an empty value by using the
# rest type as fragment is terminal
type=@frag:%{
    "type": "rest",
    "name": "fragment"
}%

# url parts with port

# www.acme.com:80/home/index.php?x=1&b=%32#top
type=@urlparts_dom_port_path_query_frag:%[
    { "type": "@dom", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@port", "name": "." },
    { "type": "@path", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@query", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@frag", "name": "." }
]%

# www.acme.com:80/home/index.php?x=1&b=%32
type=@urlparts_dom_port_path_query:%[
    { "type": "@dom", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@port", "name": "." },
    { "type": "@path", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@query", "name": "." }
]%

# www.acme.com:80/home/index.php#top
type=@urlparts_dom_port_path_frag:%[
    { "type": "@dom", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@port", "name": "." },
    { "type": "@path", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@frag", "name": "." }
]%

# www.acme.com:80?x=1&b=%32#top
type=@urlparts_dom_port_query_frag:%[
    { "type": "@dom", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@port", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@query", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@frag", "name": "." }
]%

# www.acme.com:80?x=1&b=%32
type=@urlparts_dom_port_query:%[
    { "type": "@dom", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@port", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@query", "name": "." }
]%

# www.acme.com:80/home/index.php
type=@urlparts_dom_port_path:%[
    { "type": "@dom", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@port", "name": "." },
    { "type": "@path", "name": "." }
]%

# www.acme.com:80#top
type=@urlparts_dom_port_frag:%[
    { "type": "@dom", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@port", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@frag", "name": "." }
]%

# www.acme.com:80
type=@urlparts_dom_port:%[
    { "type": "@dom", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@port", "name": "." }
]%

# url parts without port

# www.acme.com/home/index.php?x=1&b=%32#top
type=@urlparts_dom_path_query_frag:%[
    { "type": "@dom", "name": "." },
    { "type": "@path", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@query", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@frag", "name": "." }
]%

# www.acme.com/home/index.php?x=1&b=%32
type=@urlparts_dom_path_query:%[
    { "type": "@dom", "name": "." },
    { "type": "@path", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@query", "name": "." }
]%

# www.acme.com/home/index.php#top
type=@urlparts_dom_path_frag:%[
    { "type": "@dom", "name": "." },
    { "type": "@path", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@frag", "name": "." }
]%

# www.acme.com?x=1&b=%32#top
type=@urlparts_dom_query_frag:%[
    { "type": "@dom", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@query", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@frag", "name": "." }
]%

# www.acme.com?x=1&b=%32
type=@urlparts_dom_query:%[
    { "type": "@dom", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@query", "name": "." }
]%

# www.acme.com/home/index.php
type=@urlparts_dom_path:%[
    { "type": "@dom", "name": "." },
    { "type": "@path", "name": "." }
]%

# www.acme.com#top
type=@urlparts_dom_frag:%[
    { "type": "@dom", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@frag", "name": "." }
]%

# www.acme.com
type=@urlparts_dom:%[
    { "type": "@dom", "name": "." },
]%

# alternatives for url parts

type=@urlparts:%{
        "type": "alternative",
        "parser": [
{ "type": "@urlparts_dom_port_path_query_frag", "name": ".", "priority": 60010 },
{ "type": "@urlparts_dom_port_path_query", "name": ".", "priority": 60020 },
{ "type": "@urlparts_dom_port_path_frag", "name": ".", "priority": 60030 },
{ "type": "@urlparts_dom_port_query_frag", "name": ".", "priority": 60040 },
{ "type": "@urlparts_dom_port_query", "name": ".", "priority": 60050 },
{ "type": "@urlparts_dom_port_path", "name": ".", "priority": 60060 },
{ "type": "@urlparts_dom_port_frag", "name": ".", "priority": 60070 },
{ "type": "@urlparts_dom_port", "name": ".", "priority": 60080 },
{ "type": "@urlparts_dom_path_query_frag", "name": ".", "priority": 61010 },
{ "type": "@urlparts_dom_path_query", "name": ".", "priority": 61020 },
{ "type": "@urlparts_dom_path_frag", "name": ".", "priority": 61030 },
{ "type": "@urlparts_dom_query_frag", "name": ".", "priority": 61040 },
{ "type": "@urlparts_dom_query", "name": ".", "priority": 61050 },
{ "type": "@urlparts_dom_path", "name": ".", "priority": 61060 },
{ "type": "@urlparts_dom_frag", "name": ".", "priority": 61070 },
{ "type": "@urlparts_dom", "name": ".", "priority": 61080 }
        ]
}%

# authentication

# strict rfc3986
type=@authpart:%{
    "type": "string",
    "name": "..",
    "matching.mode": "lazy",
    "quoting.mode": "none",
    "quoting.escape.mode": "none",
    "matching.permitted": [
        { "class": "alnum" },
        { "chars": "-._~%%!$&'()*+,;=" }
    ]
}%

# prefixes before url parts

type=@scheme_nouser_nopass_urlparts:%[
    { "type": "char-to", "name": "scheme", "extradata": ":" },
    { "type": "literal", "text": "://:@" },
    { "type": "@urlparts", "name": "." }
]%

type=@scheme_nouser_pass_urlparts:%[
    { "type": "char-to", "name": "scheme", "extradata": ":" },
    { "type": "literal", "text": "://:" },
    { "type": "@authpart", "name": "password" },
    { "type": "literal", "text": "@" },
    { "type": "@urlparts", "name": "." }
]%

type=@scheme_user_nopass_urlparts:%[
    { "type": "char-to", "name": "scheme", "extradata": ":" },
    { "type": "literal", "text": "://" },
    { "type": "@authpart", "name": "username" },
    { "type": "literal", "text": ":@" },
    { "type": "@urlparts", "name": "." }
]%

type=@scheme_user_pass_urlparts:%[
    { "type": "char-to", "name": "scheme", "extradata": ":" },
    { "type": "literal", "text": "://" },
    { "type": "@authpart", "name": "username" },
    { "type": "literal", "text": ":" },
    { "type": "@authpart", "name": "password" },
    { "type": "literal", "text": "@" },
    { "type": "@urlparts", "name": "." }
]%

type=@scheme_user_urlparts:%[
    { "type": "char-to", "name": "scheme", "extradata": ":" },
    { "type": "literal", "text": "://" },
    { "type": "@authpart", "name": "username" },
    { "type": "literal", "text": "@" },
    { "type": "@urlparts", "name": "." }
]%

type=@scheme_urlparts:%[
    { "type": "char-to", "name": "scheme", "extradata": ":" },
    { "type": "literal", "text": "://" },
    { "type": "@urlparts", "name": "." }
]%

type=@nouser_nopass_urlparts:%[
    { "type": "literal", "text": ":@" },
    { "type": "@urlparts", "name": "." }
]%

type=@nouser_pass_urlparts:%[
    { "type": "literal", "text": ":" },
    { "type": "@authpart", "name": "password" },
    { "type": "literal", "text": "@" },
    { "type": "@urlparts", "name": "." }
]%

type=@user_nopass_urlparts:%[
    { "type": "@authpart", "name": "username" },
    { "type": "literal", "text": ":@" },
    { "type": "@urlparts", "name": "." }
]%

type=@user_pass_urlparts:%[
    { "type": "@authpart", "name": "username" },
    { "type": "literal", "text": ":" },
    { "type": "@authpart", "name": "password" },
    { "type": "literal", "text": "@" },
    { "type": "@urlparts", "name": "." }
]%

type=@user_urlparts:%[
    { "type": "@authpart", "name": "username" },
    { "type": "literal", "text": "@" },
    { "type": "@urlparts", "name": "." }
]%

# path parts

# /home/index.php?x=1&b=%32#top
type=@pathparts_path_query_frag:%[
    { "type": "@path", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@query", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@frag", "name": "." }
]%

# /home/index.php?x=1&b=%32
type=@pathparts_path_query:%[
    { "type": "@path", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@query", "name": "." }
]%

# /home/index.php#top
type=@pathparts_path_frag:%[
    { "type": "@path", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@frag", "name": "." }
]%

# /home/index.php
type=@pathparts_path:%[
    { "type": "@path", "name": "." }
]%

# alternatives for path parts

type=@pathparts:%{
        "type": "alternative",
        "parser": [
{ "type": "@pathparts_path_query_frag", "name": ".", "priority": 60010 },
{ "type": "@pathparts_path_query", "name": ".", "priority": 60020 },
{ "type": "@pathparts_path_frag", "name": ".", "priority": 60030 },
{ "type": "@pathparts_path", "name": ".", "priority": 60040 }
        ]
}%

# Workaround EOF after ']%'
