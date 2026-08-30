#!/bin/sh

# Disable proxy plugins before speed test
# Each plugin uses dual detection: UCI config enabled=1 OR process running
disable_proxy() {
	if [ "$proxy_mode" = "nil" ] || [ -z "$proxy_mode" ]; then
		return
	fi

	echolog "Checking proxy plugins to disable..."
	> /tmp/cfst_proxy_state

	# PassWall: clash ssr-redir ss-local
	_disable_proxy "passwall" "/etc/config/passwall" "passwall.@global[0].enabled" "passwall" "clash ssr-redir ss-local"
	# PassWall2: clash xray v2ray sing-box
	_disable_proxy "passwall2" "/etc/config/passwall2" "passwall2.@global[0].enabled" "passwall2" "clash xray v2ray sing-box"
	# OpenClash: clash
	_disable_proxy "openclash" "/etc/config/openclash" "openclash.config.enabled" "openclash" "clash"
	# SSR-Plus (shadowsocksr): ssr-redir ss-local ss-redir shadowsocksr
	_disable_proxy "ssrplus" "/etc/config/shadowsocksr" "shadowsocksr.@global[0].enabled" "shadowsocksr" "ssr-redir ss-local ss-redir shadowsocksr"
	# Nikki: clash ssr sing-box xray
	_disable_proxy "nikki" "/etc/config/nikki" "nikki.@global[0].enabled" "nikki" "clash ssr sing-box xray"
	# Momo: clash ssr mihomo sing-box
	_disable_proxy "momo" "/etc/config/momo" "momo.@global[0].enabled" "momo" "clash ssr mihomo sing-box"
	# HomeProxy: sing-box
	_disable_proxy "homeproxy" "/etc/config/homeproxy" "homeproxy.@global[0].enabled" "homeproxy" "sing-box"
	# dae: daed dae
	_disable_proxy "dae" "/etc/config/dae" "dae.@global[0].enabled" "dae" "daed dae"
	# daed: daed
	_disable_proxy "daed" "/etc/config/daed" "daed.@global[0].enabled" "daed" "daed"

	if [ -s /tmp/cfst_proxy_state ]; then
		sleep 2
		echolog "All proxies disabled"
	else
		echolog "No active proxies found"
	fi
}

# Helper: disable a single proxy plugin
# Args: state_name uci_config_path uci_key init_service process_names
_disable_proxy() {
	local state_name="$1"
	local uci_config_path="$2"
	local uci_key="$3"
	local init_service="$4"
	local process_names="$5"
	local uci_enabled="0"
	local process_running="0"

	# Check UCI config
	if [ -f "$uci_config_path" ]; then
		uci_enabled=$(uci get "$uci_key" 2>/dev/null) || uci_enabled="0"
		[ "$uci_enabled" = "1" ] && uci_enabled="1"
	fi

	# Check process
	for pname in $process_names; do
		if pgrep -x "$pname" >/dev/null 2>&1; then
			process_running="1"
			break
		fi
	done

	# Skip if neither UCI nor process detected
	if [ "$uci_enabled" != "1" ] && [ "$process_running" = "0" ]; then
		return
	fi

	# Disable UCI config if enabled
	if [ "$uci_enabled" = "1" ]; then
		uci set "$uci_key"="0"
		uci commit "${uci_config_path##*/}" 2>/dev/null
		echo "$state_name" >> /tmp/cfst_proxy_state
		echolog "  Disabled UCI: $state_name"
	fi

	# Stop init service if process running
	if [ "$process_running" = "1" ]; then
		/etc/init.d/$init_service stop 2>/dev/null
		echolog "  Stopped service: $state_name (process running)"
	fi
}

# Restore proxy plugins after speed test
restore_proxy() {
	if [ "$proxy_mode" = "nil" ] || [ -z "$proxy_mode" ]; then
		return
	fi

	if [ ! -f /tmp/cfst_proxy_state ] || [ ! -s /tmp/cfst_proxy_state ]; then
		return
	fi

	echolog "Restoring proxy plugins..."

	while read -r name; do
		case "$name" in
			passwall)
				uci set passwall.@global[0].enabled="1"
				uci commit passwall
				/etc/init.d/passwall start 2>/dev/null
				echolog "  Restored: PassWall"
				;;
			passwall2)
				uci set passwall2.@global[0].enabled="1"
				uci commit passwall2
				/etc/init.d/passwall2 start 2>/dev/null
				echolog "  Restored: PassWall2"
				;;
			openclash)
				uci set openclash.config.enabled="1"
				uci commit openclash
				/etc/init.d/openclash start 2>/dev/null
				echolog "  Restored: OpenClash"
				;;
			ssrplus)
				uci set shadowsocksr.@global[0].enabled="1"
				uci commit shadowsocksr
				/etc/init.d/shadowsocksr start 2>/dev/null
				echolog "  Restored: SSR-Plus"
				;;
			nikki)
				uci set nikki.@global[0].enabled="1"
				uci commit nikki
				/etc/init.d/nikki start 2>/dev/null
				echolog "  Restored: Nikki"
				;;
			momo)
				uci set momo.@global[0].enabled="1"
				uci commit momo
				/etc/init.d/momo start 2>/dev/null
				echolog "  Restored: Momo"
				;;
			homeproxy)
				uci set homeproxy.@global[0].enabled="1"
				uci commit homeproxy
				/etc/init.d/homeproxy start 2>/dev/null
				echolog "  Restored: HomeProxy"
				;;
			dae)
				uci set dae.@global[0].enabled="1"
				uci commit dae
				/etc/init.d/dae start 2>/dev/null
				echolog "  Restored: dae"
				;;
			daed)
				uci set daed.@global[0].enabled="1"
				uci commit daed
				/etc/init.d/daed start 2>/dev/null
				echolog "  Restored: daed"
				;;
		esac
	done < /tmp/cfst_proxy_state

	rm -f /tmp/cfst_proxy_state
	sleep 2
	echolog "All proxies restored"
}
