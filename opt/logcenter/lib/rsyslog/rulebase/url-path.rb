version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

include=types/url.rb

rule=:%{
    "type": "@pathparts",
    "name": "."
}%

# Workaround EOF after ']%' or '}%'
