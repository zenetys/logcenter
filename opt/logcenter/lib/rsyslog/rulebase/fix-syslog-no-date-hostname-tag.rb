version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

# Input: $rawmsg

# Fortigate logs:
# <189>logver=604081234 timestamp=1694092511 devname="FW-FORTINET" devid="ABC12ABC1234A12A" ...
# <189>date=2023-09-01 time=22:51:48 devname="FW-FORTINET" devid="AB123ABC12345678" ...
rule=:<%-:number%>logver=%-:number%%-:rest%
rule=:<%-:number%>date=2%-:rest%

# Cisco SB logs sent in rfc3164, ie. without logging origin-id hostname
# <189>%SYSLOG-N-NEWSYSLOGSERVER: configure new syslog server 10.109.21.254, aggregated (1)
rule=:<%-:number%>\x25%-:rest%

# <30>last message repeated 2 times
rule=:<%-:number%>last message repeated %-:number% times

# Huawei vrp logs
# Timezone unsupported in pmrfc3164: <190>Jul 10 2026 15:55:47+02:00 ...
# Invalid decimal number after milliseconds: <188>Jul 10 2026 15:51:30.570.1...

type=@wrong_rfc3164_date_suffix1:%{
    "type": "alternative",
    "parser": [
        { "type": "literal", "text": "+" },
        { "type": "literal", "text": "-" }
    ]
}%

type=@wrong_rfc3164_date_suffix2:%[
    { "type": "literal", "text": "." },
    { "type": "number" },
    { "type": "literal", "text": "." },
    { "type": "number" }
]%

rule=:%[
    { "type": "literal", "text": "<" },
    { "type": "number" },
    { "type": "literal", "text": ">" },
    { "type": "date-rfc3164" },
    { "type": "@wrong_rfc3164_date_suffix1" },
    { "type": "rest" }
]%

rule=:%[
    { "type": "literal", "text": "<" },
    { "type": "number" },
    { "type": "literal", "text": ">" },
    { "type": "date-rfc3164" },
    { "type": "@wrong_rfc3164_date_suffix2" },
    { "type": "rest" }
]%

# Workaround EOF after ']%' or '}%'
