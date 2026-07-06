Logging of HTTP traffic is done with an iRule sent via HSL.<br/>
Checkout F5 K000149201 for instructions on how to set it up.

K000149201: Configure iRule for logging connections via HSL<br/>
https://my.f5.com/manage/s/article/K000149201

Sample iRule:

```
when CLIENT_ACCEPTED {
	set hsl [HSL::open -proto UDP -pool /Common/Pool_ELK]
	set client_address [IP::client_addr]
	set client_port [TCP::client_port]
	set vip [IP::local_addr]
}
when HTTP_REQUEST {
	if {[HTTP::has_responded]} {
		return
	}
    set method [HTTP::method]
    set uri [HTTP::uri]
    set host [HTTP::host]
	set http_host [HTTP::host]:[TCP::local_port]
	set http_uri [string map {' \'} [HTTP::uri]]
	set http_method [HTTP::method]
	set http_version [HTTP::version]
	set http_user_agent [HTTP::header "User-Agent"]
	set http_referrer [HTTP::header "Referer"]
	set req_start_time [clock clicks -milliseconds]
	set req_contentlength [HTTP::header "Content-Length"]
	set req_cipher_name [SSL::cipher name]
	set req_cipher_version [SSL::cipher version]

}
when HTTP_RESPONSE {
	set resp_contentlength [HTTP::header "Content-Length"]
    set lb_pool [LB::server pool]
    set lb_server_addr [LB::server addr]
    set lb_server_port [LB::server port]
    set resp_start_time [clock clicks -milliseconds]
    set http_status [HTTP::status]
    set req_elapsed_time [expr {$resp_start_time - $req_start_time}]

    set s ", "
    set log_var "<190>$static::tcl_platform(machine) iRule_HTTP_traffic: client_address=$client_address:$client_port"
	append log_var $s "req_start_time=$req_start_time"
	append log_var $s "http_host=$http_host"
	append log_var $s "http_status=$http_status"
	append log_var $s "req_contentlength=$req_contentlength"
	append log_var $s "req_elapsed_time=$req_elapsed_time"
	append log_var $s "lb_pool=$lb_pool"
	append log_var $s "lb_server_addr=$lb_server_addr"
	append log_var $s "lb_server_port=$lb_server_port"
	append log_var $s "resp_contentlength=$resp_contentlength"
	append log_var $s "http_user_agent=$http_user_agent\""
	append log_var $s "http_referrer=\"$http_referrer\""
	append log_var $s "req_cipher_name=$req_cipher_name"
	append log_var $s "req_cipher_version=$req_cipher_version"
	append log_var $s "vip=$vip"
	append log_var $s "http_method=$http_method"
	append log_var $s "http_version=HTTP/$http_version"
	append log_var $s "http_uri=$http_uri"

   HSL::send $hsl $log_var
}
```
