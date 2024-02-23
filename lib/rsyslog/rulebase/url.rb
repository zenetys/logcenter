##
## Copyright(C) 2024 @ ZENETYS
## License: MIT (http://opensource.org/licenses/MIT)
##

version=2

type=@url_user:%[ { "type": "char-to", "name": "username", "extradata": ":@" } ]%
type=@url_pass:%[ { "type": "char-to", "name": "password", "extradata": "@" } ]%
type=@url_domain:%[ { "type": "char-sep", "name": "domain", "extradata": ":/?#" } ]%
type=@url_domain_more:%[ { "type": "char-to", "name": "domain", "extradata": ":/?#" } ]%
type=@url_port:%[ { "type": "number", "name": "port", "format": "number", "maxval": 65535 } ]%
type=@url_path:%[ { "type": "string", "name": "path", "matching.permitted": [{"class":"alnum"},{"chars":"/%%:@-._~!$&'()*+,;="}] } ]%
type=@url_path_more:%[ { "type": "char-to", "name": "path", "extradata": "?#" } ]%
type=@url_query:%[ { "type": "char-sep", "name": "query", "extradata": "#" } ]%
type=@url_query_more:%[ { "type": "char-to", "name": "query", "extradata": "#" } ]%
type=@url_frag:%[ { "type": "rest", "name": "fragment" } ]%


type=@url_user_pass_domain_port_path_query_frag:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_pass", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@url_query_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_user_pass_domain_port_path_query:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_pass", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@url_query", "name": "." } ]%

type=@url_user_pass_domain_port_path_frag:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_pass", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_user_pass_domain_port_path:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_pass", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "@url_path", "name": "." } ]%

type=@url_user_pass_domain_port_frag:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_pass", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_user_pass_domain_port:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_pass", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." } ]%

type=@url_user_pass_domain_path_query_frag:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_pass", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@url_query_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_user_pass_domain_path_query:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_pass", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@url_query", "name": "." } ]%

type=@url_user_pass_domain_path_frag:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_pass", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_user_pass_domain_path:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_pass", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "@url_path", "name": "." } ]%

type=@url_user_pass_domain_frag:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_pass", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_user_pass_domain:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_pass", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain", "name": "." } ]%

type=@url_user_domain_port_path_query_frag:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@url_query_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_user_domain_port_path_query:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@url_query", "name": "." } ]%

type=@url_user_domain_port_path_frag:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_user_domain_port_path:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "@url_path", "name": "." } ]%

type=@url_user_domain_port_frag:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_user_domain_port:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." } ]%

type=@url_user_domain_path_query_frag:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@url_query_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_user_domain_path_query:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@url_query", "name": "." } ]%

type=@url_user_domain_path_frag:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_user_domain_path:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "@url_path", "name": "." } ]%

type=@url_user_domain_frag:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_user_domain:%[
    { "type": "@url_user", "name": "." },
    { "type": "literal", "text": "@" },
    { "type": "@url_domain", "name": "." } ]%

type=@url_domain_port_path_query_frag:%[
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@url_query_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_domain_port_path_query:%[
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@url_query", "name": "." } ]%

type=@url_domain_port_path_frag:%[
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_domain_port_path:%[
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "@url_path", "name": "." } ]%

type=@url_domain_port_frag:%[
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_domain_port:%[
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "@url_port", "name": "." } ]%

type=@url_domain_path_query_frag:%[
    { "type": "@url_domain_more", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@url_query_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_domain_path_query:%[
    { "type": "@url_domain_more", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "?" },
    { "type": "@url_query", "name": "." } ]%

type=@url_domain_path_frag:%[
    { "type": "@url_domain_more", "name": "." },
    { "type": "@url_path_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_domain_path:%[
    { "type": "@url_domain_more", "name": "." },
    { "type": "@url_path", "name": "." } ]%

type=@url_domain_frag:%[
    { "type": "@url_domain_more", "name": "." },
    { "type": "literal", "text": "#" },
    { "type": "@url_frag", "name": "." } ]%

type=@url_after_scheme:%{
    "type": "alternative",
    "parser": [
        { "type": "@url_user_pass_domain_port_path_query_frag", "name": ".", "priority": 60109 },
        { "type": "@url_user_pass_domain_port_path_query", "name": ".", "priority": 60110 },
        { "type": "@url_user_pass_domain_port_path_frag", "name": ".", "priority": 60120 },
        { "type": "@url_user_pass_domain_port_path", "name": ".", "priority": 60119 },
        { "type": "@url_user_pass_domain_port_frag", "name": ".", "priority": 60198 },
        { "type": "@url_user_pass_domain_port", "name": ".", "priority": 60199 },
        { "type": "@url_user_pass_domain_path_query_frag", "name": ".", "priority": 60209 },
        { "type": "@url_user_pass_domain_path_query", "name": ".", "priority": 60210 },
        { "type": "@url_user_pass_domain_path_frag", "name": ".", "priority": 60219 },
        { "type": "@url_user_pass_domain_path", "name": ".", "priority": 60220 },
        { "type": "@url_user_pass_domain_frag", "name": ".", "priority": 60298 },
        { "type": "@url_user_pass_domain", "name": ".", "priority": 60299 },
        { "type": "@url_user_domain_port_path_query_frag", "name": ".", "priority": 60309 },
        { "type": "@url_user_domain_port_path_query", "name": ".", "priority": 60310 },
        { "type": "@url_user_domain_port_path_frag", "name": ".", "priority": 60319 },
        { "type": "@url_user_domain_port_path", "name": ".", "priority": 60320 },
        { "type": "@url_user_domain_port_frag", "name": ".", "priority": 60398 },
        { "type": "@url_user_domain_port", "name": ".", "priority": 60399 },
        { "type": "@url_user_domain_path_query_frag", "name": ".", "priority": 60409 },
        { "type": "@url_user_domain_path_query", "name": ".", "priority": 60410 },
        { "type": "@url_user_domain_path_frag", "name": ".", "priority": 60419 },
        { "type": "@url_user_domain_path", "name": ".", "priority": 60420 },
        { "type": "@url_user_domain_frag", "name": ".", "priority": 60498 },
        { "type": "@url_user_domain", "name": ".", "priority": 60499 },
        { "type": "@url_domain_port_path_query_frag", "name": ".", "priority": 60509 },
        { "type": "@url_domain_port_path_query", "name": ".", "priority": 60510 },
        { "type": "@url_domain_port_path_frag", "name": ".", "priority": 60519 },
        { "type": "@url_domain_port_path", "name": ".", "priority": 60520 },
        { "type": "@url_domain_port_frag", "name": ".", "priority": 60598 },
        { "type": "@url_domain_port", "name": ".", "priority": 60599 },
        { "type": "@url_domain_path_query_frag", "name": ".", "priority": 60609 },
        { "type": "@url_domain_path_query", "name": ".", "priority": 60610 },
        { "type": "@url_domain_path_frag", "name": ".", "priority": 60619 },
        { "type": "@url_domain_path", "name": ".", "priority": 60620 },
        { "type": "@url_domain_frag", "name": ".", "priority": 60698 },
        { "type": "@url_domain", "name": ".", "priority": 60699 },
    ] }%

type=@url_with_scheme:%[
        { "type": "char-to", "name": "scheme", "extradata": ":" },
        { "type": "literal", "text": "://" },
        { "type": "@url_after_scheme", "name": "." }
    ]%

type=@url:%{
    "type": "alternative",
    "parser": [
        { "type": "@url_with_scheme", "name": "." },
        { "type": "@url_after_scheme", "name": ".", "priority": 65535 }
    ] }%

rule=:%[
    { "type": "@url", "name": "." } ]%
