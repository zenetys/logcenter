version=2

include=types/ip.rb
include=types/percent.rb

# Cisco IOS

# %SEC-6-IPACCESSLOGRP: list 177 denied igmp 109.21.100.108 -> 224.0.0.22, 1 packet
# %SEC-6-IPACCESSLOGSP: list INBOUND-ON-J21 denied igmp 109.21.100.108 -> 224.0.0.2 (20), 1 packet
# %SEC-6-IPACCESSLOGNP: list 171 denied 0 109.21.100.108 -> 255.255.255.255, 1 packet
# %IPV6-6-ACCESSLOGP: list ACL-IPv6-K3/0-IN/10 permitted tcp 2001:DE2:1::1(1027) -> 2001:DE2:1::2(22), 9 packets
# %SEC-6-IPACCESSLOGP: list 177 denied udp 109.21.100.108(55250) -> 109.21.100.255(15600), 1 packet
# %SEC-6-IPACCESSLOGDP: list 151 denied icmp 109.21.100.108 -> 109.21.100.109 (3/4), 1 packet
rule=cisco.ios.acl:%
    { "type": "@percent" }%%
    { "type": "string-to", "extradata": "ACCESS" }%ACCESS%
    { "type": "char-to", "extradata": ":" }%: list %
    { "type": "char-to", "name": "rule.name", "extradata": " " }% %
    { "type": "char-to", "name": "event.action", "extradata": " " }% %
    { "type": "char-to", "name": "network.transport", "extradata": " " }% %
    { "type": "@ip2", "name": "source.ip" }%%
    { "type": "alternative", "parser": [
            [
                { "type": "literal", "text": "(" },
                { "type": "number", "name": "source.port", "format": "number" },
                { "type": "literal", "text": ")" }
            ],
            [
                { "type": "char-sep", "extradata": " ", "priority": 65535 }
            ]
        ] }% -> %
    { "type": "@ip2", "name": "destination.ip" }%%
    { "type": "alternative", "parser": [
            [
                { "type": "literal", "text": "(" },
                { "type": "number", "name": "destination.port", "format": "number" },
                { "type": "literal", "text": ")" }
            ],
            [
                { "type": "char-sep", "extradata": ", ", "priority": 65535 }
            ]
        ] }%%
    { "type": "alternative", "parser": [
            [
                { "type": "literal", "text": " (" },
                { "type": "number", "name": "_packet_type", "format": "number" },
                { "type": "literal", "text": ")" }
            ],
            [
                { "type": "char-sep", "extradata": ",", "priority": 65535 }
            ]
        ] }%, %
    { "type": "number", "name": "source.packets", "format": "number" }% packet%
    { "type": "rest" }%

# %SEC-6-IPACCESSLOGS: list VLAN67-IN denied 8.8.4.4 180 packets
rule=cisco.ios.acl:%
    { "type": "@percent" }%%
    { "type": "string-to", "extradata": "ACCESS" }%ACCESS%
    { "type": "char-to", "extradata": ":" }%: list %
    { "type": "char-to", "name": "rule.name", "extradata": " " }% %
    { "type": "char-to", "name": "event.action", "extradata": " " }% %
    { "type": "char-to", "name": "source.ip", "extradata": " " }% %
    { "type": "number", "name": "source.packets", "format": "number" }% packet%
    { "type": "rest" }%

annotate=cisco.ios.acl:+event.category="network"

# %IP-4-DUPADDR: Duplicate address 10.109.21.12 on Vlan262, sourced by 001f.1118.32b2
rule=cisco.ios.dupaddr:%
    { "type": "@percent" }%%
    { "type": "string-to", "extradata": "DUPADDR" }%DUPADDR: Duplicate address %
    { "type": "@ip2", "name": "source.ip" }% on %
    { "type": "char-to", "name": "observer.ingress.interface.name", "extradata": "," }%, sourced by %
    { "type": "word", "name": "source.mac" }%%
    { "type": "rest" }%

annotate=cisco.ios.dupaddr:+event.category="network"

# %IPPHONE-6-REGISTER_NEW: ephone-21:ATA001759A23CBB IP:10.109.21.120 Socket:2 DeviceType:Phone has registered.
# %IPPHONE-6-UNREGISTER_NORMAL: ephone-21:ATA001759A23CBB IP:10.109.21.120 Socket:2 DeviceType:Phone has unregistered normally.
rule=cisco.ios.phone:%
    { "type": "@percent" }%IPPHONE%
    { "type": "string-to", "extradata": "IP:" }%IP:%
    { "type": "@ip2", "name": "source.ip" }%%
    { "type": "rest" }%

# %PARSER-5-CFGLOG_LOGGEDCMD: User:admin  logged command:radius-server vsa send accounting
rule=cisco.ios.config:%
    { "type": "@percent" }%%
    { "type": "string-to", "extradata": "LOGGEDCMD" }%LOGGEDCMD: User:%
    { "type": "char-to", "name": "user.name", "extradata": " " }%%
    { "type": "whitespace" }%%
    { "type": "rest" }%

# %SYS-5-CONFIG_I: Configured from console by admin on vty1 (10.109.21.149)
rule=cisco.ios.config:%
    { "type": "@percent" }%%
    { "type": "string-to", "extradata": "CONFIG" }%CONFIG%
    { "type": "char-to", "extradata": ":" }%: Configured from %
    { "type": "string-to", "extradata": " by " }% by %
    { "type": "alternative", "parser": [
            [
                { "type": "char-to", "name": "user.name", "extradata": " " },
                { "type": "string-to", "extradata": " (" },
                { "type": "literal", "text": " (" },
                { "type": "@ip2", "name": "source.ip" },
                { "type": "literal", "text": ")" },
                { "type": "rest" }
            ],
            { "type": "word", "name": "user.name", "priority": 65535 }
        ] }%

annotate=cisco.ios.config:+event.category="configuration"

# %SEC_LOGIN-5-LOGIN_SUCCESS: Login Success [user: admin] [Source: 10.109.21.149] [localport: 22] at 15:04:36 CET Wed Aug 12 2020
# %SEC_LOGIN-4-LOGIN_FAILED: Login failed [user: ] [Source: 10.109.21.149] [localport: 22] [Reason: Login Authentication Failed] at 15:29:52 CET Wed Aug 12 2020
rule=cisco.ios.auth:%
    { "type": "@percent" }%SEC_LOGIN%
    { "type": "char-to", "extradata": ":" }%: Login %
    { "type": "char-to", "name": "event.action", "extradata": " " }% [user: %
    { "type": "alternative", "parser": [
            { "type": "char-to", "name": "user.name", "extradata": "]" },
            { "type": "char-sep", "extradata": "]", "priority": 65535 }
        ] }%] [Source: %
    { "type": "char-sep", "name": "source.ip", "extradata": "]" }%]%
    { "type": "rest" }%

# %RADIUS-4-RADIUS_ALIVE: RADIUS server 10.109.21.12:1812,1813 is being marked alive.
# %RADIUS-4-RADIUS_DEAD: RADIUS server 10.109.21.12:1812,1813 is not responding.
rule=cisco.ios.auth:%
    { "type": "@percent" }%RADIUS%
    { "type": "char-to", "extradata": ":" }%: RADIUS server %
    { "type": "@ip2", "name": "destination.ip" }%%
    { "type": "rest" }%

# %SNMP-3-AUTHFAIL: Authentication failure for SNMP req from host 10.109.21.163
rule=cisco.ios.auth:%
    { "type": "@percent" }%SNMP%
    { "type": "char-to", "extradata": ":" }%: Authentication failure for SNMP req from host %
    { "type": "@ip2", "name": "source.ip" }%%
    { "type": "rest" }%

# %SSH-5-SSH2_CLOSE: SSH2 Session from 10.109.21.149 (tty = 0) for user 'admin' using crypto cipher 'aes256-ctr', hmac 'hmac-sha1' closed
rule=cisco.ios.auth:%
    { "type": "@percent" }%SSH%
    { "type": "char-to", "extradata": ":" }%: SSH%
    { "type": "string-to", "extradata": " from " }% from %
    { "type": "@ip2", "name": "source.ip" }%%
    { "type": "string-to", "extradata": "for user '" }%for user '%
    { "type": "char-to", "name": "user.name", "extradata": "'" }%'%
    { "type": "rest" }%

# %SSH-5-SSH2_SESSION: SSH2 Session request from 10.109.21.149 (tty = 0) using crypto cipher 'aes256-ctr', hmac 'hmac-sha1' Succeeded
rule=cisco.ios.auth:%
    { "type": "@percent" }%SSH%
    { "type": "char-to", "extradata": ":" }%: SSH%
    { "type": "string-to", "extradata": " from " }% from %
    { "type": "@ip2", "name": "source.ip" }%%
    { "type": "string-to", "extradata": "' " }%' %
    { "type": "word", "name": "event.action" }%%
    { "type": "rest" }%

# %SSH-5-SSH2_USERAUTH: User '' authentication for SSH2 Session from 10.109.21.149 (tty = 0) using crypto cipher 'aes256-ctr', hmac 'hmac-sha1' Failed
rule=cisco.ios.auth:%
    { "type": "@percent" }%SSH%
    { "type": "char-to", "extradata": ":" }%: User '%
    { "type": "alternative", "parser": [
            { "type": "char-to", "name": "user.name", "extradata": "'" },
            { "type": "char-sep", "extradata": "'", "priority": 65535 }
        ] }%'%
    { "type": "string-to", "extradata": " from " }% from %
    { "type": "@ip2", "name": "source.ip" }%%
    { "type": "string-to", "extradata": "' " }%' %
    { "type": "word", "name": "event.action" }%%
    { "type": "rest" }%

annotate=cisco.ios.auth:+event.category="authentication"

# %DOT1X-5-FAIL: Authentication failed for client (0023.b53e.3e12) on Interface Gi1/0/3 AuditSessionID 0C65633E00032EF22F9CBDFE
# %DOT1X-5-FAIL: Switch 2 R0/0: smd:  Authentication failed for client (002A.C102.3EB4) on Interface Gi4/0/22 AuditSessionID 0C65633E00032EF22F9CBDFE
# %MAB-5-FAIL: Authentication failed for client (00e0.db47.858a) on Interface Gi3/0/36 AuditSessionID 0C65633E00032EF22F9CBDFE
rule=cisco.ios.dot1x:%[
    { "type": "string-to", "extradata": "Authentication " },
    { "type": "literal", "text": "Authentication " } ,
    { "type": "char-to", "name": "event.action", "extradata": " " },
    { "type": "literal", "text": " for client (" }, 
    { "type": "char-to", "name": "source.mac", "extradata": ")" },
    { "type": "literal", "text": ") on Interface " },
    { "type": "char-to", "name": "observer.ingress.interface.name", "extradata": " " },
    { "type": "literal", "text": " AuditSessionID " },
    { "type": "char-sep", "name": "cisco.audit_session_id", "extradata": " .," },
    { "type": "rest" } ]%

# %SESSION_MGR-5-FAIL: Switch 3 R0/0: smd:  Authorization failed or unapplied for client (002A.C102.3EB4) on Interface GigabitEthernet3/0/4 AuditSessionID 0C65633E00032EF22F9CBDFE
# %SESSION_MGR-5-FAIL: Chassis 2 R0/0: wncd: Authorization failed or unapplied for client (00e0.db47.858a) on Interface capwap_90000004 AuditSessionID 0C65633E00032EF22F9CBDFE. Failure Reason: VLAN Failure. Failed attribute name Vlan123.
rule=cisco.ios.dot1x:%[
    { "type": "string-to", "extradata": "Authorization " },
    { "type": "literal", "text": "Authorization " } ,
    { "type": "char-to", "name": "event.action", "extradata": " " },
    { "type": "literal", "text": " or unapplied for client (" }, 
    { "type": "char-to", "name": "source.mac", "extradata": ")" },
    { "type": "literal", "text": ") on Interface " },
    { "type": "char-to", "name": "observer.ingress.interface.name", "extradata": " " },
    { "type": "literal", "text": " AuditSessionID " },
    { "type": "char-sep", "name": "cisco.audit_session_id", "extradata": " .," },
    { "type": "rest" } ]%

annotate=cisco.ios.dot1x:+event.category="network"

# Cisco NX

# %AAA-6-AAA_ACCOUNTING_MESSAGE: start:10.109.21.79@pts/0:admin:
# %AAA-6-AAA_ACCOUNTING_MESSAGE: update:10.109.21.79@pts/0:admin:terminal length 0 (SUCCESS)
# %AAA-6-AAA_ACCOUNTING_MESSAGE: stop:10.109.21.79@pts/0:admin:shell terminated gracefully
# %AAA-6-AAA_ACCOUNTING_MESSAGE: stop:10.109.21.78@pts/0:admin:shell terminated because of session timeout
# %AAA-6-AAA_ACCOUNTING_MESSAGE: update:10.109.21.79@pts/0:admin:configure terminal ; vlan 501 (REDIRECT))
# %AAA-6-AAA_ACCOUNTING_MESSAGE: update:10.109.21.79@pts/0:admin:configure terminal ; vlan 501 (SUCCESS)
# %AAA-6-AAA_ACCOUNTING_MESSAGE: update:10.109.21.79@pts/0:admin:configure terminal ; vlan 501 ; name WIFI_GUEST (SUCCESS)
# %AAA-6-AAA_ACCOUNTING_MESSAGE: start:ppm.4055:admin:
# %AAA-6-AAA_ACCOUNTING_MESSAGE: update:ppm.4055 (sp-commit):admin:configure sync ; interface Ethernet101/1/10 (REDIRECT))
# %AAA-6-AAA_ACCOUNTING_MESSAGE: update:ppm.4055 (sp-commit):admin:configure sync ; interface Ethernet101/1/10 (SUCCESS)
# %AAA-6-AAA_ACCOUNTING_MESSAGE: update:ppm.4055 (sp-commit):admin:configure sync ; interface Ethernet101/1/10 ; no shutdown (SUCCESS)
# %AAA-6-AAA_ACCOUNTING_MESSAGE: start:vsh.19419:admin:
# %AAA-6-AAA_ACCOUNTING_MESSAGE: stop:vsh.19419:admin:
# %AAA-6-AAA_ACCOUNTING_MESSAGE: update:10.109.21.78@pts/0:admin:configure sync ; switch-profile KOL ; commit (FAILURE)
# %AAA-6-AAA_ACCOUNTING_MESSAGE: start:10.109.21.79@pts/1:admin:
# %AAA-6-AAA_ACCOUNTING_MESSAGE: update:10.109.21.79@pts/1:admin:configure sync (SUCCESS)
prefix=%[
    { "type": "@percent" },
    { "type": "literal", "text": "AAA-" },
    { "type": "number" },
    { "type": "literal", "text": "-AAA_ACCOUNTING_MESSAGE: " } ]%

type=@cisco_nx_accounting_source:%{
    "type": "alternative",
    "parser": [
        [
            { "type": "@ip2", "name": "source.ip" },
            { "type": "literal", "text": "@" },
            { "type": "char-to", "name": "cisco.terminal", "extradata": ":" }
        ],
        { "type": "char-to", "name": "cisco.source", "extradata": ":", "priority": 50000 }
    ] }%

rule=cisco.nx.accounting:%[
    { "type": "char-to", "name": "event.action", "extradata": ":" },
    { "type": "literal", "text": ":" },
    { "type": "@cisco_nx_accounting_source", "name": "." },
    { "type": "literal", "text": ":" },
    { "type": "char-to", "name": "user.name", "extradata": ":" },
    { "type": "rest" } ]%

annotate=cisco.nx.accounting:+event.category="configuration"

# %VSHD-5-VSHD_SYSLOG_CONFIG_I: Configured from vty by admin on 172.30.0.1@pts/0
prefix=%[
    { "type": "@percent" },
    { "type": "char-to", "extradata": ": " },
    { "type": "literal", "text": ": " } ]%

rule=cisco.nx.config:%[
    { "type": "literal", "text": "Configured from " },
    { "type": "string-to", "extradata": " by " },
    { "type": "literal", "text": " by " },
    { "type": "char-to", "name": "user.name", "extradata": " " },
    { "type": "literal", "text": " on " },
    { "type": "@ip2", "name": "source.ip" },
    { "type": "literal", "text": "@" },
    { "type": "char-sep", "name": "cisco.terminal", "extradata": " " },
    { "type": "rest" } ]%

annotate=cisco.nx.config:+event.category="configuration"

type=@cisco_nx_arp_dup_ip_iface:%{
    "type": "alternative",
    "parser": [
        [   { "type": "literal", "text": "(" },
            { "type": "char-to", "name": "observer.ingress.interface.name", "extradata": ")" },
            { "type": "literal", "text": ") " } ],
        [   { "type": "literal", "text": " " } ]
    ]}%

type=@cisco_nx_arp_dup_ip_text:%{
    "type": "alternative",
    "parser": [
        { "type": "literal", "text": "is duplicate of local virtual ip" },
        { "type": "literal", "text": "with destination set to our local ip" },
        { "type": "literal", "text": "with destination set to our local Virtual ip" }
    ]}%

prefix=%[
    { "type": "@percent" },
    { "type": "literal", "text": "ARP-" },
    { "type": "number" },
    { "type": "literal", "text": "-DUP_" } ]%

# %ARP-3-DUP_VADDR_SRC_IP:  arp [4372]  Source address of packet received from 0000.5e00.0a02 on Vlan300(port-channel10) is duplicate of local virtual ip, 172.16.15.1
# %ARP-3-DUP_SRCIP_PROBE: Duplicate address Detected. Probe packet received from [chars] on [chars] with destination set to our local ip, [chars]
# %ARP-3-DUP_VADDR_SRCIP_PROBE: Duplicate address Detected. Probe packet received from [chars] on [chars] with destination set to our local Virtual ip, [chars]
rule=cisco.nx.dupaddr:%[
    { "type": "string-to", "extradata": "packet received from " },
    { "type": "literal", "text": "packet received from " } ,
    { "type": "char-to", "name": "source.mac", "extradata": " " },
    { "type": "literal", "text": " on Vlan" }, 
    { "type": "number", "name": "observer.ingress.vlan.id", "format": "number" },
    { "type": "@cisco_nx_arp_dup_ip_iface", "name": "." },
    { "type": "@cisco_nx_arp_dup_ip_text" },
    { "type": "literal", "text": ", " },
    { "type": "char-sep", "name": "cisco.conflict_ip", "extradata": " ," },
    { "type": "rest" } ]%

annotate=cisco.nx.dupaddr:+event.category="network"
