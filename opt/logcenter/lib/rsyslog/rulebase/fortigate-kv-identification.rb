version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# Input: $msg ($.msg)

# fields sequence [... d]evname="..." devid="FG..."
type=@forti_kv_devame_devid:%[
    { "type": "string-to", "extradata": "evname=\"" },
    { "type": "literal", "text": "evname=\"" },
    { "type": "char-to", "extradata": "\"" },
    { "type": "literal", "text": "\" devid=\"FG" },
    { "type": "char-to", "extradata": "\"" }
]%

# fields sequence [... d]ate=... time=...
# may be first fields, before or after devname and devid
type=@forti_kv_date_time:%[
    { "type": "string-to", "extradata": "ate=" },
    { "type": "literal", "text": "ate=" },
    { "type": "date-iso" },
    { "type": "literal", "text": " time=" },
    { "type": "time-24hr" }
]%

# <something> logid="..."
# assumed to be not right after one of the sequences above
type=@forti_kv_logid:%[
    { "type": "string-to", "extradata": " logid=\"" },
    { "type": "literal", "text": " logid=\"" },
    { "type": "number" },
    { "type": "literal", "text": "\"" }
]%

# main rule

type=@forti_kv_main_001:%[
    { "type": "@forti_kv_date_time" },
    { "type": "@forti_kv_devame_devid" },
    { "type": "@forti_kv_logid" },
    { "type": "rest" }
]%

type=@forti_kv_main_002:%[
    { "type": "@forti_kv_devame_devid" },
    { "type": "@forti_kv_date_time" },
    { "type": "@forti_kv_logid" },
    { "type": "rest" }
]%

rule=:%{
    "type": "alternative",
    "parser": [
        { "type": "@forti_kv_main_001", "priority": 60000 },
        { "type": "@forti_kv_main_002", "priority": 60020 }
    ]
}%

# Workaround EOF after ']%' or '}%'
