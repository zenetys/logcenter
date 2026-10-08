# Standalone Windows events forward with NXLog

- Paste the following content to `C:\program files\nxlog\nxlog.d\10-xm-json.conf`

```xml
<Extension _json>
    Module      xm_json
</Extension>
```

- Paste the following content to `C:\program files\nxlog\nxlog.d\20-out-logcenter.conf`
- Adjust the target syslog host

```xml
<Output out_logcenter>
    Module          om_tcp
    Host            logcenter-syslog-collector.acme.loc
    Port            514
</Output>
```

- Paste the following content to `C:\program files\nxlog\nxlog.d\70-windows-events.conf`
- Possibly adjust the XML query to match the desired events


```xml
<Input in_windows_events>
    Module          im_msvistalog
    # Channel         Security

    <QueryXML>
        <QueryList>
            <Query Id='0'>
                <Select Path='Security'>*</Select>
                <!--
                <Select Path='Application'>*</Select>
                <Select Path='Setup'>*</Select>
                <Select Path='System'>*</Select>
                -->
            </Query>
        </QueryList>
    </QueryXML>

    # TRUE: Send events from the last saved position if present or from
    # NXLog start if no previously saved position is available. Do not
    # set to FALSE otherwise the module will always read all events on
    # NXLog start.
    ReadFromLast    TRUE

    # TRUE: Save position when NXLog exits. Having ReadFromLast TRUE and
    # SavePos FALSE allows to send only events emitted after NXLog start.
    SavePos         FALSE

    # EventTime modification: need a real universal timestamp
    # since there is no timezone information.
    <Exec>
        $HumanMessage = $Message;
        delete($Message);
        delete($SourceModuleName);
        delete($SourceModuleType);
        $EventTimeEpoch = string(integer($EventTime)/1000000) + "." + \
            string(microsecond($EventTime));
        $EventReceivedTimeEpoch = string(integer($EventReceivedTime)/1000000) + "." + \
            string(microsecond($EventReceivedTime));
        $Message = to_json();
        $SourceName = "nxlog-msvistalog";
        to_syslog_bsd();
    </Exec>
</Input>

<Route rt_windows_events>
    Path    in_windows_events => out_logcenter
</Route>
```

- Restart the nxlog service

```
PS> Restart-Service nxlog
```

# Windows Event Collector (WEC) events forward with NXLog

In case of a WEC host, the same configuration as above can be used, with the
XML query adjusted to select events from the ForwardedEvents channel:

```xml
    <QueryXML>
        <QueryList>
            <Query Id='0'>
                <Select Path='ForwardedEvents'>*</Select>
                <!--
                <Select Path='Security'>*</Select>
                <Select Path='Application'>*</Select>
                <Select Path='Setup'>*</Select>
                <Select Path='System'>*</Select>
                -->
            </Query>
        </QueryList>
    </QueryXML>
```
