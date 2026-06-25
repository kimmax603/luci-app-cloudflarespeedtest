#!/bin/sh

# Disable proxy plugins before speed test
disable_proxy() {
	if [ "$proxy_mode" = "nil" ] || [ -z "$proxy_mode" ]; then
		return
	fi

	echolog "Checking proxy plugins to disable..."
	> /tmp/cfst_proxy_state

	# PassWall
	if [ -f /etc/config/passwall ]; then
		local v=$(uci get passwall.@global[0].enabled 2>/dev/null)
		if [ "$v" = "1" ]; then
			uci set passwall.@global[0].enabled="0"
			uci commit passwall
			/etc/init.d/passwall stop 2>/dev/null
			echo "passwall" >> /tmp/cfst_proxy_state
			echolog "  Disabled: PassWall"
		fi
	fi

	# PassWall2
	if [ -f /etc/config/passwall2 ]; then
		local v=$(uci get passwall2.@global[0].enabled 2>/dev/null)
		if [ "$v" = "1" ]; then
			uci set passwall2.@global[0].enabled="0"
			uci commit passwall2
			/etc/init.d/passwall2 stop 2>/dev/null
			echo "passwall2" >> /tmp/cfst_proxy_state
			echolog "  Disabled: PassWall2"
		fi
	fi

	# OpenClash
	if [ -f /etc/config/openclash ]; then
		local v=$(uci get openclash.config.enable 2>/dev/null)
		if [ "$v" = "1" ]; then
			uci set openclash.config.enable="0"
			uci commit openclash
			/etc/init.d/openclash stop 2>/dev/null
			echo "openclash" >> /tmp/cfst_proxy_state
			echolog "  Disabled: OpenClash"
		fi
	fi

	# SSR-Plus
	if [ -f /etc/config/shadowsocksr ]; then
		local v=$(uci get shadowsocksr.@global[0].enabled 2>/dev/null)
		if [ "$v" = "1" ]; then
			uci set shadowsocksr.@global[0].enabled="0"
			uci commit shadowsocksr
			/etc/init.d/shadowsocksr stop 2>/dev/null
			echo "ssrplus" >> /tmp/cfst_proxy_state
			echolog "  Disabled: SSR-Plus"
		fi
	fi

	# Nikki
	if [ -f /etc/config/nikki ]; then
		local v=$(uci get nikki.config.enable 2>/dev/null)
		if [ "$v" = "1" ]; then
			uci set nikki.config.enable="0"
			uci commit nikki
			/etc/init.d/nikki stop 2>/dev/null
			echo "nikki" >> /tmp/cfst_proxy_state
			echolog "  Disabled: Nikki"
		fi
	fi

	# Momo
	if [ -f /etc/config/momo ]; then
		local v=$(uci get momo.config.enable 2>/dev/null)
		if [ "$v" = "1" ]; then
			uci set momo.config.enable="0"
			uci commit momo
			/etc/init.d/momo stop 2>/dev/null
			echo "momo" >> /tmp/cfst_proxy_state
			echolog "  Disabled: Momo"
		fi
	fi

	# HomeProxy
	if [ -f /etc/config/homeproxy ]; then
		local v=$(uci get homeproxy.@global[0].enabled 2>/dev/null)
		if [ "$v" = "1" ]; then
			uci set homeproxy.@global[0].enabled="0"
			uci commit homeproxy
			/etc/init.d/homeproxy stop 2>/dev/null
			echo "homeproxy" >> /tmp/cfst_proxy_state
			echolog "  Disabled: HomeProxy"
		fi
	fi

	# dae
	if [ -f /etc/config/dae ]; then
		local v=$(uci get dae.config.enabled 2>/dev/null)
		if [ "$v" = "1" ]; then
			uci set dae.config.enabled="0"
			uci commit dae
			/etc/init.d/dae stop 2>/dev/null
			echo "dae" >> /tmp/cfst_proxy_state
			echolog "  Disabled: dae"
		fi
	fi

	# daed
	if [ -f /etc/config/daed ]; then
		local v=$(uci get daed.config.enabled 2>/dev/null)
		if [ "$v" = "1" ]; then
			uci set daed.config.enabled="0"
			uci commit daed
			/etc/init.d/daed stop 2>/dev/null
			echo "daed" >> /tmp/cfst_proxy_state
			echolog "  Disabled: daed"
		fi
	fi

	if [ -s /tmp/cfst_proxy_state ]; then
		sleep 2
		echolog "All proxies disabled"
	else
		echolog "No active proxies found"
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
				uci set openclash.config.enable="1"
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
				uci set nikki.config.enable="1"
				uci commit nikki
				/etc/init.d/nikki start 2>/dev/null
				echolog "  Restored: Nikki"
				;;
			momo)
				uci set momo.config.enable="1"
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
				uci set dae.config.enabled="1"
				uci commit dae
				/etc/init.d/dae start 2>/dev/null
				echolog "  Restored: dae"
				;;
			daed)
				uci set daed.config.enabled="1"
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
