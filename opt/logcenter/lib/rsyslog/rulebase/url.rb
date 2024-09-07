version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

include=types/url.rb

rule=:%{
        "type": "alternative",
        "parser": [
{ "type": "@scheme_nouser_nopass_urlparts", "name": ".", "priority": 60000 },
{ "type": "@scheme_nouser_pass_urlparts", "name": ".", "priority": 60030 },
{ "type": "@scheme_user_nopass_urlparts", "name": ".", "priority": 60050 },
{ "type": "@scheme_user_pass_urlparts", "name": ".", "priority": 60100 },
{ "type": "@scheme_user_urlparts", "name": ".", "priority": 60200 },
{ "type": "@scheme_urlparts", "name": ".", "priority": 60300 },
{ "type": "@nouser_nopass_urlparts", "name": ".", "priority": 61000 },
{ "type": "@nouser_pass_urlparts", "name": ".", "priority": 61030 },
{ "type": "@user_nopass_urlparts", "name": ".", "priority": 61050 },
{ "type": "@user_pass_urlparts", "name": ".", "priority": 61100 },
{ "type": "@user_urlparts", "name": ".", "priority": 61200 },
{ "type": "@urlparts", "name": ".", "priority": 61600 }
        ]
}%

# Workaround EOF after ']%' or '}%'
