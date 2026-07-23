# Exchange MSGTRK log forward with NXLog

- Paste the following content to `C:\program files\nxlog\nxlog.d\20-out-logcenter.conf`
- Adjust the target syslog host

```xml
<Output out_logcenter>
    Module          om_tcp
    Host            logcenter-syslog-collector.acme.loc
    Port            514
 </Output>
```

- Paste the following content to `C:\program files\nxlog\nxlog.d\70-exchange-msgtrk.conf`
- Adjust the path of the files to watch in the input section

```xml
<Input in_exchange_msgtrk>
    Module  im_file
    File    "D:\\TransportRoles\\Logs\\MessageTracking\\*.log"
    ReadFromLast TRUE
    SavePos FALSE
    <Exec>
        $SourceName = "nxlog-exchange-msgtrk";
        $FileName = file_name();
        to_syslog_ietf();
    </Exec>
</Input>

<Route rt_exchange_msgtrk>
    Path    in_exchange_msgtrk => out_logcenter
</Route>
```

- Restart the nxlog service

```
PS> Restart-Service nxlog
```
