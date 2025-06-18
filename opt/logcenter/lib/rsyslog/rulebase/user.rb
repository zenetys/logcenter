version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

include=types/user.rb

rule=:%{ "type": "@user", "name": "." }%

# Workaround EOF after ']%' or '}%'
