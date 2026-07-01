#!/bin/sh

LOG_FILE='/var/log/cloudflarespeedtest.log'
IP_FILE='/usr/share/cloudflarespeedtestresult.txt'
IPV4_TXT='/usr/share/CloudflareSpeedTest/ip.txt'
IPV6_TXT='/usr/share/CloudflareSpeedTest/ipv6.txt'
IP_URL_V4='https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ip.txt'
IP_URL_V6='https://raw.githubusercontent.com/XIU2/CloudflareSpeedTest/master/ipv6.txt'

# Source proxy management
. /usr/bin/cloudflarespeedtest/proxy.sh

download_ip_list() {
	mkdir -p /usr/share/CloudflareSpeedTest
	if [ -f "${IPV4_TXT}" ] && [ -s "${IPV4_TXT}" ]; then
		echolog "IP list exists ($(wc -l < ${IPV4_TXT}) IPs), skip download"
		return
	fi
	echolog "Downloading IP list..."
	curl -sL --connect-timeout 10 --max-time 30 "${IP_URL_V4}" -o ${IPV4_TXT} 2>/dev/null
	[ $? -eq 0 ] && [ -s "${IPV4_TXT}" ] && echolog "IPv4 IP list downloaded: $(wc -l < ${IPV4_TXT}) IPs" || echolog "Failed to download IPv4 IP list"
	curl -sL --connect-timeout 10 --max-time 30 "${IP_URL_V6}" -o ${IPV6_TXT} 2>/dev/null
	[ $? -eq 0 ] && [ -s "${IPV6_TXT}" ] && echolog "IPv6 IP list downloaded: $(wc -l < ${IPV6_TXT}) IPs" || echolog "Failed to download IPv6 IP list"
}

get_global_config() { while [ "$*" != "" ]; do eval ${1}='`uci get cloudflarespeedtest.global.$1`' 2>/dev/null; shift; done; }
get_cf_dns_config() { while [ "$*" != "" ]; do eval cf_dns_${1}='`uci get cloudflarespeedtest.cf_dns.$1`' 2>/dev/null; shift; done; }
echolog() { local d="$(date "+%Y-%m-%d %H:%M:%S")"; echo -e "$d: $*"; echo -e "$d: $*" >> $LOG_FILE; }

read_config() {
	get_global_config "speed" "custome_url" "threads" "custome_cors_enabled" "custome_cron" "tp" "dt" "dn" "dd" "tl" "tll" "tlr" "sl" "t" "allip" "debug" "ipv6_enabled" "advanced" "proxy_mode" "httping" "httping_code" "cfcolo" "p" "ip_data"
	get_cf_dns_config "enabled" "email" "api_key" "zone_id" "domain" "sub_domain" "proxied" "ttl" "delete_old" "update_mode" "max_records" "telegram_enabled" "telegram_bot_token" "telegram_chat_id" "telegram_api" "pushplus_enabled" "pushplus_token"
}

speed_test() {
	rm -rf $LOG_FILE

	if [ -x "/usr/bin/cloudflarespeedtest/cfst" ]; then
		CFST_CMD="/usr/bin/cloudflarespeedtest/cfst"
	elif [ -x "/usr/bin/cfst" ]; then
		CFST_CMD="/usr/bin/cfst"
	elif command -v cfst >/dev/null 2>&1; then
		CFST_CMD="cfst"
	else
		echolog "Error: cfst not found! Please reinstall the package."
		return 1
	fi

	disable_proxy

	local command="${CFST_CMD} -o ${IP_FILE}"
	if [ "$ipv6_enabled" = "1" ]; then
		command="${command} -f ${IPV6_TXT}"
	else
		command="${command} -f ${IPV4_TXT}"
	fi
	[ -n "$custome_url" ] && command="${command} -url ${custome_url}"

	if [ "$advanced" = "1" ]; then
		[ -n "$threads" ] && [ "$threads" -gt 0 ] 2>/dev/null && command="${command} -n ${threads}"
		[ -n "$t" ] && [ "$t" -gt 0 ] 2>/dev/null && command="${command} -t ${t}"
		[ -n "$tp" ] && [ "$tp" != "443" ] && command="${command} -tp ${tp}"
		[ -n "$tl" ] && command="${command} -tl ${tl}"
		[ -n "$tll" ] && command="${command} -tll ${tll}"
		[ -n "$tlr" ] && command="${command} -tlr ${tlr}"
		[ -n "$dn" ] && [ "$dn" -gt 0 ] 2>/dev/null && command="${command} -dn ${dn}"
		[ -n "$dt" ] && [ "$dt" -gt 0 ] 2>/dev/null && command="${command} -dt ${dt}"
		[ -n "$sl" ] && [ "$sl" != "0" ] && command="${command} -sl ${sl}"
		[ "$dd" = "1" ] && command="${command} -dd"
		[ "$httping" = "1" ] && command="${command} -httping"
		[ "$httping" = "1" ] && [ -n "$httping_code" ] && command="${command} -httping-code ${httping_code}"
		[ "$httping" = "1" ] && [ -n "$cfcolo" ] && command="${command} -cfcolo ${cfcolo}"
		[ -n "$p" ] && command="${command} -p ${p}"
		[ -n "$ip_data" ] && command="${command} -ip ${ip_data}"
		[ "$allip" = "1" ] && command="${command} -allip"
		[ "$debug" = "1" ] && command="${command} -debug"
	else
		command="${command} -tl 200 -tll 40 -n 100 -t 4 -dt 10 -dn 1"
	fi

	echolog "----------- start speed test ----------"
	echolog "Command: $command"
	$command >> $LOG_FILE 2>&1
	echolog "----------- end speed test ----------"
	restore_proxy
}

update_cloudflare_dns() {
	local bestip="$1"
	local region="$2"
	if [ "$cf_dns_enabled" != "1" ]; then return; fi
	if [ -z "$cf_dns_api_key" ] || [ -z "$cf_dns_email" ] || [ -z "$cf_dns_zone_id" ] || [ -z "$cf_dns_domain" ] || [ -z "$cf_dns_sub_domain" ]; then
		echolog "Cloudflare DNS config incomplete, skip DNS update"
		return
	fi
	local full_domain="${cf_dns_sub_domain}.${cf_dns_domain}"
	local record_type="A"
	echo "$bestip" | grep -q ":" && record_type="AAAA"
	local api_url="https://api.cloudflare.com/client/v4/zones/${cf_dns_zone_id}/dns_records"
	if [ "$cf_dns_delete_old" = "1" ]; then
		echolog "Deleting old DNS records for ${full_domain}..."
		local old_records=$(curl -s -X GET "${api_url}?name=${full_domain}" -H "X-Auth-Email: ${cf_dns_email}" -H "X-Auth-Key: ${cf_dns_api_key}" -H "Content-Type: application/json")
		local record_ids=$(echo "$old_records" | jsonfilter -e '@.result[*].id' 2>/dev/null)
		for rid in $record_ids; do
			[ -n "$rid" ] && curl -s -X DELETE "${api_url}/${rid}" -H "X-Auth-Email: ${cf_dns_email}" -H "X-Auth-Key: ${cf_dns_api_key}" -H "Content-Type: application/json" > /dev/null 2>&1 && echolog "Deleted record: $rid" && sleep 1
		done
	fi
	local cf_proxied="false"
	[ "$cf_dns_proxied" = "1" ] && cf_proxied="true"
	> /tmp/cfst_dns_result
	if [ "$cf_dns_update_mode" = "single" ]; then
		echolog "Creating DNS record: ${full_domain} -> ${bestip} (${record_type})"
		local result=$(curl -s -X POST "${api_url}" -H "X-Auth-Email: ${cf_dns_email}" -H "X-Auth-Key: ${cf_dns_api_key}" -H "Content-Type: application/json" -d "{\"type\":\"${record_type}\",\"name\":\"${full_domain}\",\"content\":\"${bestip}\",\"ttl\":${cf_dns_ttl},\"proxied\":${cf_proxied}}")
		local success=$(echo "$result" | jsonfilter -e '@.success' 2>/dev/null)
		if [ "$success" = "true" ]; then
			echolog "DNS record created successfully: ${full_domain} -> ${bestip}"
			echo "IP地址 ${bestip} [${region}] 成功导入到 ${full_domain}" >> /tmp/cfst_dns_result
		else
			echolog "Failed to create DNS record: $result"
			echo "IP地址 ${bestip} [${region}] 导入失败" >> /tmp/cfst_dns_result
		fi
	else
		echolog "Multi-IP mode: creating DNS records for ${full_domain}..."
		local count=0
		local limit="${cf_dns_max_records:-5}"
		tail -n +2 "${IP_FILE}" | while IFS=, read -r ip sent recv loss avg_delay speed region; do
			[ -z "$ip" ] && continue
			count=$((count + 1))
			[ "$limit" -gt 0 ] 2>/dev/null && [ $count -gt "$limit" ] && break
			local rtype="A"; echo "$ip" | grep -q ":" && rtype="AAAA"
			echolog "Creating DNS record: ${full_domain} -> ${ip} (${rtype})"
			curl -s -X POST "${api_url}" -H "X-Auth-Email: ${cf_dns_email}" -H "X-Auth-Key: ${cf_dns_api_key}" -H "Content-Type: application/json" -d "{\"type\":\"${rtype}\",\"name\":\"${full_domain}\",\"content\":\"${ip}\",\"ttl\":${cf_dns_ttl},\"proxied\":${cf_proxied}}" > /dev/null 2>&1
			echo "IP地址 ${ip} [${region}] 成功导入到 ${full_domain}" >> /tmp/cfst_dns_result
			sleep 1
		done
		echolog "Created DNS records for ${full_domain}"
	fi
}

send_telegram() {
	local message="$1"
	[ "$cf_dns_telegram_enabled" != "1" ] || [ -z "$cf_dns_telegram_bot_token" ] || [ -z "$cf_dns_telegram_chat_id" ] && return
	local api_host="${cf_dns_telegram_api:-api.telegram.org}"
	curl -s -X POST "https://${api_host}/bot${cf_dns_telegram_bot_token}/sendMessage" -d "chat_id=${cf_dns_telegram_chat_id}" -d "text=${message}" > /dev/null 2>&1
	echolog "Telegram notification sent"
}

send_pushplus() {
	local message="$1"
	[ "$cf_dns_pushplus_enabled" != "1" ] || [ -z "$cf_dns_pushplus_token" ] && return
	curl -s -X POST "https://www.pushplus.plus/send" -d "token=${cf_dns_pushplus_token}" -d "title=CF Speed Test" -d "content=${message}" > /dev/null 2>&1
	echolog "Pushplus notification sent"
}

ip_replace() {
	bestip=$(sed -n '2,1p' ${IP_FILE} | awk -F, '{print $1}')
	region=$(sed -n '2,1p' ${IP_FILE} | awk -F, '{print $7}')
	[ -z "${bestip}" ] && { echolog "No valid IP found"; return; }
	echolog "Best IP: ${bestip} [${region}]"
	update_cloudflare_dns "$bestip" "$region"
	local notification_msg=""
	if [ -f /tmp/cfst_dns_result ] && [ -s /tmp/cfst_dns_result ]; then
		while IFS= read -r line; do
			[ -n "$notification_msg" ] && notification_msg="${notification_msg}
"
			notification_msg="${notification_msg}${line} ($(date '+%Y-%m-%d %H:%M:%S'))"
		done < /tmp/cfst_dns_result
	else
		notification_msg="Best IP: ${bestip} [${region}]
Time: $(date '+%Y-%m-%d %H:%M:%S')"
	fi
	echolog "$notification_msg"
	echolog "----------- DNS update complete ----------"
	send_telegram "$notification_msg"
	send_pushplus "$notification_msg"
}

read_config

if [ "$1" ]; then
	case "$1" in
		start) download_ip_list; speed_test; ip_replace ;;
		test) download_ip_list; speed_test ;;
		replace) ip_replace ;;
		updateiplist) rm -f ${IPV4_TXT} ${IPV6_TXT}; download_ip_list ;;
	esac
	exit
fi
