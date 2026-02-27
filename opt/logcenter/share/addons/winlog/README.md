# Windows Event Collector (WEC) NXLog configuration

Sample C:\program files\nxlog\nxlog.d\windows.conf

```
<Extension _json>
    Module      xm_json
</Extension>

<Input in_events>
    Module          im_msvistalog
    # Channel         Security

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

<Output out_tcp>
    Module          om_tcp
    Host            logcenter-syslog-collector.acme.loc
    Port            514
</Output>

<Route rt_events>
    Path            in_events => out_tcp
</Route>
```
