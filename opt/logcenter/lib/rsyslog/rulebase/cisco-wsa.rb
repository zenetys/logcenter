version=2

##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

include=types/ip.rb

type=@string:%{
    "type": "alternative",
    "parser": [
        { "type": "string", "name": "..", "quoting.mode": "required", "matching.mode": "lazy" },
        { "type": "char-sep", "name": "..", "extradata": " " }
     ] }%

type=@csv_string:%{
    "type": "alternative",
    "parser": [
        { "type": "string", "name": "..", "quoting.mode": "required", "matching.mode": "lazy" },
        { "type": "char-sep", "name": "..", "extradata": "," }
     ] }%

type=@user__dom_user_realm:%[
    { "type": "literal", "text": "\"" },
    { "type": "char-to", "name": "user.domain", "extradata": "\\" },
    { "type": "literal", "text": "\\" },
    { "type": "char-to", "name": "user.name", "extradata": "@" },
    { "type": "literal", "text": "@" },
    { "type": "char-to", "name": "cisco.wsa.auth_realm", "extradata": "\"" },
    { "type": "literal", "text": "\"" }
]%

type=@user__dom_user:%[
    { "type": "literal", "text": "\"" },
    { "type": "char-to", "name": "user.domain", "extradata": "\\" },
    { "type": "literal", "text": "\\" },
    { "type": "char-to", "name": "user.name", "extradata": "\"" },
    { "type": "literal", "text": "\"" }
]%

type=@user__default:%[
    { "type": "literal", "text": "\"" },
    { "type": "char-to", "name": "user.name", "extradata": "\"" },
    { "type": "literal", "text": "\"" }
]%

type=@user:%{
    "type": "alternative",
    "parser": [
        { "type": "literal", "text": "-", "priority": "100" },
        { "type": "literal", "text": "\"\"", "priority": "200" },
        { "type": "@user__dom_user_realm", "name": ".", "priority": "300" },
        { "type": "@user__dom_user", "name": ".", "priority": "400" },
        { "type": "@user__default", "name": ".", "priority": "500" },
    ] }%

type=@destination:%{
    "type": "alternative",
    "parser": [
        { "type": "literal", "text": "-", "priority": "100" },
        { "type": "@ip", "name": "destination.ip", "priority": "200" },
        { "type": "char-to", "name": "destination.domain", "extradata": " ", "priority": "300" }
    ] }%

# Access logs, log style squid
rule=cisco.wsa.access:%[
    { "type": "char-to", "name": "log.level", "extradata": ":" }, { "type": "literal", "text": ": " },
    { "type": "float", "name": "@timestamp", "format": "number" }, { "type": "literal", "text": " " },
    { "type": "number", "name": "cisco.wsa.elapsed_time_ms", "format": "number" }, { "type": "literal", "text": " " },
    { "type": "@ip", "name": "client.ip" }, { "type": "literal", "text": " " },
    { "type": "char-to", "name": "cisco.wsa.result_code", "extradata": "/" }, { "type": "literal", "text": "/" },
    { "type": "number", "name": "http.response.status_code", "format": "number" }, { "type": "literal", "text": " " },
    { "type": "number", "name": "http.response.bytes", "format": "number" }, { "type": "literal", "text": " " },
    { "type": "char-to", "name": "http.request.method", "extradata": " " }, { "type": "literal", "text": " " },
    { "type": "char-to", "name": "url.original", "extradata": " " }, { "type": "literal", "text": " " },
    { "type": "@user", "name": "." }, { "type": "literal", "text": " " },
    { "type": "char-to", "name": "cisco.wsa.hierarchy", "extradata": "/" }, { "type": "literal", "text": "/" },
    { "type": "@destination", "name": "." }, { "type": "literal", "text": " " },
    { "type": "@string", "name": "http.response.mime_type" }, { "type": "literal", "text": " " },
    { "type": "char-to", "name": "cisco.wsa.acltag", "extradata": " " }, { "type": "literal", "text": " <" },
    { "type": "@csv_string", "name": "cisco.wsa.webcat_code_abbr" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.wbrs_score" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.webroot_scanverdict" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.webroot_threat_name" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.webroot_trr" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.webroot_spyid" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.webroot_trace_id" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.mcafee_scanverdict" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.mcafee_filename" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.mcafee_av_scanerror" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.mcafee_av_detecttype" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.mcafee_av_virustype" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.mcafee_virus_name" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.sophos_scanverdict" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.sophos_scanerror" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.sophos_file_name" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.sophos_virus_name" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.ids_verdict" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.icap_verdict" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.webcat_req_code_abbr" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.webcat_resp_code_abbr" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.resp_dvs_verdictname" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.wbrs_threat_type" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.google_translate_enc_url" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.app" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.app_type" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.behavior" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.request_rewrite" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.avg_bw" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.bw_throttled" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.user_type" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.req_dvs_verdictname" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.req_dvs_threat_name" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.amp_verdict" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.amp_malware_name" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.amp_score" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.amp_upload" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.amp_filename" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.amp_sha" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.ext_archivescan_blockedfiletype" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.ext_archivescan_verdict" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.ext_archivescan_threatdetail" }, { "type": "literal", "text": "," },
    { "type": "@csv_string", "name": "cisco.wsa.ext_wtt_behavior" }, { "type": "literal", "text": "," },
    { "type": "char-to", "name": "cisco.wsa.ext_youtube_url_category", "extradata": ">" }, { "type": "literal", "text": "> " },
    { "type": "@string", "name": "cisco.wsa.suspect-user-agent" },
    { "type": "rest" } ]%

annotate=cisco.wsa.access:+event.provider="access"
annotate=cisco.wsa.access:+event.category="network,web"
