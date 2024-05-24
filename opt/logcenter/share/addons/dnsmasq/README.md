# dnsmasq

Option `log-queries=extra` is required in dnsmasq. It allows to join request and replies with [serial, source ip, source port].

Caveats:

* dnsmasq 2.79 / no reply log for queries type MX, NS, type=65 seen, works probably well only for A or AAAA queries
* dnsmasq 2.79 / no extra header in queries type TXT, cannot join query with reply
