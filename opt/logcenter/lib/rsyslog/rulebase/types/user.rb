version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

type=@ustr:%{
    "type": "string",
    "name": "..",
    "quoting.mode": "none",
    "quoting.escape.mode": "none",
    "matching.mode": "lazy",
    "matching.permitted": [
        { "class": "alnum" },
        { "chars": "._-+" }
    ]
}%

type=@user_backslash1:%[
    { "type": "@ustr", "name": "user.domain" },
    { "type": "literal", "text": "\\" },
    { "type": "@ustr", "name": "user.name" }
]%

type=@user_backslash2:%[
    { "type": "@ustr", "name": "user.domain" },
    { "type": "literal", "text": "\\\\" },
    { "type": "@ustr", "name": "user.name" }
]%

type=@user_at:%[
    { "type": "@ustr", "name": "user.name" },
    { "type": "literal", "text": "@" },
    { "type": "@ustr", "name": "user.domain" }
]%

type=@user:%{
    "type": "alternative",
    "parser": [
        { "type": "@user_backslash2", "name": ".", "priority": 1000 },
        { "type": "@user_backslash1", "name": ".", "priority": 2000 },
        { "type": "@user_at", "name": ".", "priority": 3000 },
        { "type": "@ustr", "name": "user.name", "priority": 65535 }
    ] }%
