### SMC log server setup

Note: adjust `$INSTALL_DIR` to fit your SMC installation directory, eg: `/usr/local/forcepoint/smc`.

```sh
INSTALL_DIR=/data/forcepoint/smc
```

Create a template file `$INSTALL_DIR/data/fields/syslog_templates/custom_syslog_conf.xml` derivated from the default one `default_syslog_conf.xml`. Add the following extra fields :

* Dstif
* DST_VLAN
* SIT_CATEGORY
* SERVICE
* IPS_APPID
* DNS_QCLASS
* DNS_QTYPE
* DNS_QNAME
* DNS_CLASS
* DNS_TYPE
* DNS_NAME
* DNS_ADDR
* URL
* ISP
* RELATED_CONNECTION_REF

Field RELATED_CONNECTION_REF is interesting because it allows to group all logs related to the same connection. A bug in JSON output was observed in SMC 7.2.4, an extra comma is sometimes seen before the closing bracket of the object. This does not disturb rsyslog. Example, note the `,}}` at the end which makes the JSON invalid:

```
{...,"RELATEDCONNECTIONREF":{"RefCompId":"FW node 1",...,"RefCreationTime":"2025-08-27T11:09:08.799+02:00",}}
```

The following commands can be used to create the custom template file:

```sh
awk -v x=Dstif,DST_VLAN,SIT_CATEGORY,SERVICE,IPS_APPID,DNS_QCLASS,DNS_QTYPE,DNS_QNAME,DNS_CLASS,DNS_TYPE,DNS_NAME,DNS_ADDR,URL,ISP,RELATED_CONNECTION_REF '
  /<\/fieldreflist>/ {
    print "<!-- custom -->";
    l = split(x, xx, ",");
    for (i=1; i<=l; i++) print "<fieldref>"xx[i]"</fieldref>";
  }
  { print; }
' $INSTALL_DIR/data/fields/syslog_templates/default_syslog_conf.xml \
  > $INSTALL_DIR/data/fields/syslog_templates/custom_syslog_conf.xml
```

Edit `$INSTALL_DIR/LogServerConfiguration.txt` to instruct the log server to use the custom template and to write timestamp in RFC3339 format with milliseconds :

```sh
cat >> $INSTALL_DIR/LogServerConfiguration.txt <<EOF

# custom
SYSLOG_CONF_FILE=$INSTALL_DIR/data/fields/syslog_templates/custom_syslog_conf.xml
JSON_EXPORT_DATE_FORMAT=yyyy-MM-dd'T'HH:mm:ss.SSSXXX
EOF
```

Restart the log server :

```sh
systemctl restart sgLogServer
```
 
### SMC interface > Inspection policy > Exceptions

Edit the inspection policy of the firewall to log some situations related to interesting protocols:

* **Situations:**
  * DNS_Client-Question-Logged
  * DNS_Record-Address-Logged
  * TLS_Server-Certificate-Processed
  * URL_Category-Accounting
  * TLS_SNI-Processed
  * HTTP_URL-Processed
* **Severity:** ANY
* **Logical interface:** ANY
* **Source:** *your-internal-networks*
* **Destination:** ANY
* **Protocol:** ANY
* **Action:** Permit
* **Logging:** Stored

### SMC interface > LogServer > Properties > Log Forwarding

Setup a rule to forward firewall logs to the logcenter:

* **Target Host:** *your-logcenter-collector-address*
* **Service:** TCP
* **Port:** 514
* **Format:** JSON
* **Data Type:** All Log Data
* **Filter:** NOT Type:(Diagnostic, Debug low, Debug mid, Debug high)
