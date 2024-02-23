##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

version=2

type=@user:%{
    "type": "alternative",
    "parser": [
        [   { "type": "char-to", "name": "user.domain", "extradata": "\\" },
            { "type": "literal", "text": "\\" },
            { "type": "char-to", "name": "user.name", "extradata": " " }
        ],
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
