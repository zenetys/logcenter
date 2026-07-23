version=2

type=@percent:%%

# Standard field type ipv6 does not recognize well some IPv6
# representations (seen with Cisco logs). This may be used as
# an alternative. The lazy mode allow to stop for instance on
# a colon ":" character, but may cause incorrect matching if
# there is not a literal to match after.
type=@ip2:%{
    "type": "alternative",
    "parser": [
        { "type": "ipv4", "name": ".." },
        {
            "type": "string", "name": "..",
            "quoting.mode": "none",
            "matching.mode": "lazy",
            "matching.permitted": [
                { "class": "hexdigit" },
                { "chars": ":" }
            ]
        }
    ]
}%

type=@ip_win_csv1:%[
        { "type": "@ip2", "name": ".." }
]%

type=@ip_win_csv2:%[
        { "type": "@ip2", "name": ".." },
        { "type": "@percent" },
        { "type": "char-to", "extradata": "," }
]%

type=@ip_win_csv:%{
    "type": "alternative",
    "parser": [
        { "type": "@ip_win_csv2", "name": "..", "priority": 0 },
        { "type": "@ip_win_csv1", "name": ".." },
        { "type": "literal", "name": "..", "text": "", "priority": 65535 }
    ]
}%

type=@string:%{
    "type": "alternative",
    "parser": [
        { "type": "string", "name": "..", "quoting.mode": "required", "matching.mode": "lazy" },
        { "type": "char-sep", "name": "..", "extradata": "," }
     ]
}%

# schema version 15.02.1258.028
# schema version 15.02.1544.014
rule=exchange.msgtrk:%[
    { "type": "@string", "name": "@timestamp" }, { "type": "literal", "text": "," },
    { "type": "@ip_win_csv", "name": "exchange.msgtrk.client_ip" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.client_hostname" }, { "type": "literal", "text": "," },
    { "type": "@ip_win_csv", "name": "exchange.msgtrk.server_ip" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.server_hostname" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.source_context" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.connector_id" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.source" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.event_id" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.internal_message_id" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.message_id" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.network_message_id" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.recipient_address" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.recipient_status" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.total_bytes" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.recipient_count" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.related_recipient_address" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.reference" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.message_subject" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.sender_address" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.return_path" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.message_info" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.directionality" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.tenant_id" }, { "type": "literal", "text": "," },
    { "type": "@ip_win_csv", "name": "exchange.msgtrk.original_client_ip" }, { "type": "literal", "text": "," },
    { "type": "@ip_win_csv", "name": "exchange.msgtrk.original_server_ip" }, { "type": "literal", "text": "," }, 
    { "type": "@string", "name": "exchange.msgtrk.custom_data" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.transport_traffic_type" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.log_id" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.schema_version" }
]%

# old schema version
rule=exchange.msgtrk:%[
    { "type": "@string", "name": "@timestamp" }, { "type": "literal", "text": "," },
    { "type": "@ip_win_csv", "name": "exchange.msgtrk.client_ip" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.client_hostname" }, { "type": "literal", "text": "," },
    { "type": "@ip_win_csv", "name": "exchange.msgtrk.server_ip" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.server_hostname" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.source_context" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.connector_id" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.source" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.event_id" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.internal_message_id" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.message_id" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.network_message_id" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.recipient_address" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.recipient_status" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.total_bytes" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.recipient_count" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.related_recipient_address" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.reference" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.message_subject" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.sender_address" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.return_path" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.message_info" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.directionality" }, { "type": "literal", "text": "," },
    { "type": "@string", "name": "exchange.msgtrk.tenant_id" }, { "type": "literal", "text": "," },
    { "type": "@ip_win_csv", "name": "exchange.msgtrk.original_client_ip" }, { "type": "literal", "text": "," },
    { "type": "@ip_win_csv", "name": "exchange.msgtrk.original_server_ip" }, { "type": "literal", "text": "," }, 
    { "type": "@string", "name": "exchange.msgtrk.custom_data" },
    { "type": "rest" }
]%

# Workaround EOF after ']%' or '}%'
