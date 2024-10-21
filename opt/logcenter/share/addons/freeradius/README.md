### /etc/raddb/mods-enabled/linelog

```
linelog linelog_auth_default {
  filename = syslog
  syslog_facility = daemon
  syslog_severity = info
  reference = "messages.%{reply:Packet-Type}"
  messages {
    Access-Accept = "**Auth-Access-Accept** %{pairs:request:}"
    Access-Reject = "**Auth-Access-Reject** %{pairs:request:}"
  }
}
```

### /etc/raddb/site-enabled/\<site>

```
server <site> {
  post-auth {
    [...]
    linelog_auth_default
    [...]

    Post-Auth-Type REJECT {
      [...]
      linelog_auth_default
      [...]
    }
  }
}
```
