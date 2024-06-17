version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

type=@user_backslash1:%[
    { "type": "char-to", "name": "user.domain", "extradata": "\\" },
    { "type": "literal", "text": "\\" },
    { "type": "char-to", "name": "user.name", "extradata": " " }
]%

type=@user_backslash2:%[
    { "type": "char-to", "name": "user.domain", "extradata": "\\\\" },
    { "type": "literal", "text": "\\\\" },
    { "type": "char-to", "name": "user.name", "extradata": " " }
]%

type=@user:%{
    "type": "alternative",
    "parser": [
        { "type": "@user_backslash2", "name": ".", "priority": 1000 },
        { "type": "@user_backslash1", "name": ".", "priority": 2000 },
        { "type": "char-to", "name": "user.name", "extradata": " " }
    ] }%

type=@user_csv:%{
    "type": "alternative",
    "name": ".",
    "parser": [
        [   { "type": "char-to", "name": "user.domain", "extradata": "\\" },
            { "type": "literal", "text": "\\" },
            { "type": "char-to", "name": "user.name", "extradata": "," }
        ],
        { "type": "char-sep", "name": "user.name", "extradata": "," }
    ] }%
