# Office 365 Log Pollers

This document describes how to set up the Microsoft Entra ID (Azure AD) application
and permissions required by the two polling scripts:

* **o365-audit-poll** — polls the Office 365 Management Activity API for audit events
  (Exchange, SharePoint, Azure AD, etc.)
* **o365-msgtrk-poll** — polls the Microsoft Graph API for Exchange Online message
  traces (mail flow logs)

Both scripts authenticate using certificate-based client credentials (RS256 JWT
client assertion).

## 1. Generate a certificate and private key

Generate a self-signed certificate and private key using OpenSSL. The certificate
will be uploaded to Entra ID to authenticate the application.

```
openssl req -x509 -newkey rsa:2048 -nodes -keyout o365-zlc-logs.key \
    -out o365-zlc-logs.crt -days $((365*3)) -subj '/CN=o365-zlc-logs'
```

## 2. Register the application in Entra ID

* Go to [Microsoft Entra admin center](https://entra.microsoft.com/)
* Navigate to **App registrations**
* Click **New registration**
  * Name: `o365-zlc-logs`
  * Supported account types: **Single tenant only - [TENANT]**
  * Redirect URI: leave empty
* Click **Register**

### Upload the certificate

* In the newly created app registration, go to **Certificates & secrets**
* Select the **Certificates** tab
* Click **Upload certificate** and upload `o365-zlc-logs.crt`

### Note the application identifiers

In the app registration **Overview** page, note the following values that
would be requested to configure the polling scripts:

| Entra field | Config variable |
|---|---|
| **Application (client) ID** | `O365_APPLICATION_ID` |
| **Directory (tenant) ID** | `O365_TENANT_ID` |

## 3. Permissions for o365-audit-poll (Management Activity API)

* In **Entra ID > App registration**, tab **All applications**, `o365-zlc-logs`, go to **API permissions**
* Click **Add a permission**
* Select **APIs my organization uses**, search for `Office 365 Management APIs`
* Select **Application permissions**
* Check **ActivityFeed.Read** and **ActivityFeed.ReadDlp**
* Click **Add permissions**
* Click **Grant admin consent for [TENANT]** and confirm

## 4. Permissions for o365-msgtrk-poll (Graph messageTraces API)

### Add the Graph permission

* In **Entra ID > App registration**, tab **All applications**, `o365-zlc-logs`, go to **API permissions**
* Click **Add a permission**
* Select **Microsoft Graph**
* Select **Application permissions**
* Search for `ExchangeMessageTrace.Read.All` and check it
* Click **Add permissions**
* Click **Grant admin consent for [TENANT]** and confirm

### Assign the Global Reader role

The Graph messageTraces API requires the **Global Reader** directory role
in addition to the API permission.

* In **Entra ID > Roles & admins**, go to **All roles**
* Search for **Global Reader** and click on it
* Click **Add assignments**
* Search for `o365-zlc-logs` (the app registration name) and select it
* Click **Add**

### Provision the Microsoft Message Trace service principal

The Graph messageTraces API requires a service principal for Microsoft's internal
Message Trace application to be provisioned in your tenant.

Using [Microsoft Graph Explorer](https://developer.microsoft.com/en-us/graph/graph-explorer),
sign in as an administrator and run the following request:

* Method: **POST**
* URL: **https://graph.microsoft.com/v1.0/servicePrincipals**
* Request body: **{"appId":"8bd644d1-64a1-4d4b-ae52-2e0cbf64e373"}**
* Modify Permissions: **Application.ReadWrite.All**

Alternatively, you can use PowerShell:

```
Install-Module Microsoft.Graph.Applications
Import-Module Microsoft.Graph.Applications
Connect-MgGraph -Scopes Application.ReadWrite.All
New-MgServicePrincipal -AppId 8bd644d1-64a1-4d4b-ae52-2e0cbf64e373
```

Provisioning may take several hours. During this time, requests to the messageTraces
API may return `401 Unauthorized`.