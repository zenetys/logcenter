Log format extending squid standard format with KV fields, for instance to log
ssl_bump mode and sni:

```
logformat squid_ssl_bump %ts.%03tu %6tr %>a %Ss/%03>Hs %<st %rm %ru %[un %Sh/%<a %mt squid.ssl.bump_mode=%ssl::bump_mode squid.ssl.sni=%ssl::>sni
access_log syslog:local0.info squid_ssl_bump is_log_ssl_bump
access_log syslog:local0.info squid !is_log_ssl_bump
```
