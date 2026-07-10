version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# Input: $rawmsg-after-pri
# Input: $.msg if $rawmsg-after-pri was moved to $.msg

# Jul 08 2026 09:35:45+02:00 DST A21-BW03 %%01WLAN/4/AC_AUTHENTICATE_FAIL(l)[293764]:Failed to authenticate ...
# Jan 08 2026 09:35:40+01:00 A21-BW03 %%01WLAN/4/AC_AUTHENTICATE_FAIL(l)[293764]:Failed to authenticate ...
# Jul 08 2026 09:35:40.460.1+02:00 DST A21-BW03 %%01WLAN/4/AC_AUTHENTICATE_FAIL(l)[293764]:Failed to authenticate ...
# Jan 08 2026 09:35:40.460.1+01:00 A21-BW03 %%01WLAN/4/AC_AUTHENTICATE_FAIL(l)[293764]:Failed to authenticate ...
# Jul 08 2026 09:35:40.460.1+02:00 DST A21-BW03 INFO/4/IC_LOGFILE_AGING:OID 1.3.6.1.4.1.2011.5.25.212.2.2 One log ...
# Jul 08 2026 09:35:40.460.1+02:00 DST A21-BW03 %%01SEC/6/BIND(L): An initial portrange is assigned ...
# Jul 13 2026 15:10:24 A21-SW01 %%01DHCP/6/SNP_RCV_MSG(l)[4250065]:DHCP snooping received a message. ...
# %%01WLAN/4/AC_AUTHENTICATE_FAIL(l)
# INFO/4/IC_LOGFILE_AGING

type=@digits:%{
    "type": "string",
    "matching.mode": "lazy",
    "quoting.mode": "none",
    "quoting.escape.mode": "none",
    "matching.permitted": [ { "class": "digit" } ],
    "name": ".."
}%

type=@ucstring:%{
    "type": "string",
    "matching.mode": "lazy",
    "quoting.mode": "none",
    "quoting.escape.mode": "none",
    "matching.permitted": [ { "chars": "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_" } ],
    "name": ".."
}%

# Jan 08 2026 09:35:40+01:00
# Jul 08 2026 09:35:40.460.1+02:00
type=@date1:%[
    { "type": "char-to", "extradata": " " },
    { "type": "literal", "text": " " },
    { "type": "@digits"},
    { "type": "literal", "text": " " },
    { "type": "@digits"},
    { "type": "literal", "text": " " },
    { "type": "@digits"},
    { "type": "literal", "text": ":" },
    { "type": "@digits"},
    { "type": "literal", "text": ":" },
    { "type": "@digits"},
    { "type": "char-sep", "extradata": "+-" },
    { "type": "char-to", "extradata": ":" },
    { "type": "literal", "text": ":" },
    { "type": "@digits" }
]%
type=@date2:%[
    { "type": "@date1" },
    { "type": "literal", "text": " DST" }
]%
type=@date:%{
    "type": "alternative",
    "parser": [
        { "type": "@date2", "priority": 100 },
        { "type": "@date1", "priority": 200 },
        { "type": "date-rfc3164", "priority": 300 },
    ]
}%

# %%01WLAN/4/AC_AUTHENTICATE_FAIL(l)[293764]
# INFO/4/IC_LOGFILE_AGING
# %%01SEC/6/BIND(L)
type=@huawei_log_type:%[
    { "type": "literal", "text": "(" },
    { "type": "char-to", "extradata": ")", "name": "huawei.logtype" },
    { "type": "literal", "text": ")" }
]%
type=@huawei_log_seq:%[
    { "type": "literal", "text": "[" },
    { "type": "number", "name": "huawei.logseq", "format": "number" },
    { "type": "literal", "text": "]" }
]%
type=@huawei_log_brief_type:%[
    { "type": "@ucstring", "name": "huawei.brief" },
    { "type": "@huawei_log_type", "name": "." }
]%
type=@huawei_log_brief_type_seq:%[
    { "type": "@ucstring", "name": "huawei.brief" },
    { "type": "@huawei_log_type", "name": "." },
    { "type": "@huawei_log_seq", "name": "." }
]%
type=@huawei_log_brief:%{
    "type": "alternative",
    "parser": [
        { "type": "@huawei_log_brief_type_seq", "name": ".", "priority": 200 },
        { "type": "@huawei_log_brief_type", "name": ".", "priority": 500 },
        { "type": "@ucstring", "name": "huawei.brief", "priority": 800 }
    ]
}%
type=@huawei_header1:%[
    { "type": "@ucstring", "name": "huawei.module" },
    { "type": "literal", "text": "/" },
    { "type": "number", "name": "huawei.level", "format": "number" },
    { "type": "literal", "text": "/" },
    { "type": "@huawei_log_brief", "name": "." }
]%
type=@huawei_header2:%[
    { "type": "literal", "text": "%%" },
    { "type": "number", "name": "huawei.logver", "format": "number" },
    { "type": "@huawei_header1", "name": "." }
]%
type=@huawei_header:%{
    "type": "alternative",
    "parser": [
        { "type": "@huawei_header1", "name": ".", "priority": 200 },
        { "type": "@huawei_header2", "name": ".", "priority": 100 }
    ]
}%

type=@huawei_message1:%{
    "type": "rest",
    "name": "huawei.message"
}%
type=@huawei_message2:%[
    { "type": "whitespace" },
    { "type": "@huawei_message1", "name": "." }
]%
type=@huawei_message:%{
    "type": "alternative",
    "parser": [
        { "type": "@huawei_message1", "name": ".", "priority": 200 },
        { "type": "@huawei_message2", "name": ".", "priority": 100 }
    ]
}%

rule=:%[
    { "type": "@date" },
    { "type": "literal", "text": " " },
    { "type": "char-to", "extradata": " ", "name": "huawei.hostname" },
    { "type": "literal", "text": " " },
    { "type": "@huawei_header", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@huawei_message", "name": "." }
]%

rule=:%[
    { "type": "@huawei_header", "name": "." }
]%

# Workaround EOF after ']%' or '}%'
