require("luci.sys")

m = Map("cloudflarespeedtest")
m.title = translate("Cloudflare DNS Update")
m.description = translate("Configure Cloudflare DNS API to update DNS records after speed test")

s = m:section(NamedSection, "cf_dns")
s.addremove = false
s.anonymous = true

o = s:option(Flag, "enabled", translate("Enable DNS Update"))
o.description = translate("Automatically update Cloudflare DNS records after speed test")
o.rmempty = false
o.default = 0

o = s:option(Value, "email", translate("Cloudflare Email"))
o.description = translate("Your Cloudflare account email")
o.rmempty = true

o = s:option(Value, "api_key", translate("API Key"))
o.description = translate("Cloudflare Global API Key")
o.rmempty = true
o.password = true

o = s:option(Value, "zone_id", translate("Zone ID"))
o.description = translate("Cloudflare Zone ID, found in the API section of the dashboard")
o.rmempty = true

o = s:option(Value, "domain", translate("Domain"))
o.description = translate("Root domain, e.g. example.com")
o.rmempty = true

o = s:option(Value, "sub_domain", translate("Subdomain"))
o.description = translate("Subdomain, e.g. 'cf' for cf.example.com. Leave empty for root domain")
o.rmempty = true

o = s:option(Flag, "proxied", translate("Orange Cloud"))
o.description = translate("Enable Cloudflare CDN proxy, hide origin server IP")
o.rmempty = true
o.default = 0

o = s:option(ListValue, "ttl", translate("TTL"))
o:value("1", translate("Auto"))
o:value("60", translate("1 min"))
o:value("300", translate("5 min"))
o:value("3600", translate("1 hour"))
o.default = "1"

o = s:option(Flag, "delete_old", translate("Delete Old Records"))
o.description = translate("Delete existing DNS records before creating new ones")
o.rmempty = true
o.default = 1

o = s:option(ListValue, "update_mode", translate("Update Mode"))
o:value("single", translate("Single IP (best)"))
o:value("multi", translate("Multi-IP"))
o.default = "single"

o = s:option(Value, "max_records", translate("Max Records"))
o.description = translate("Maximum DNS records in multi mode (0=unlimited)")
o.datatype = "uinteger"
o.default = 5
o.rmempty = true
o:depends("update_mode", "multi")

-- [[ Notification Settings ]] --

s2 = m:section(NamedSection, "cf_dns", translate("Notification"))
s2.anonymous = true

o = s2:option(Flag, "telegram_enabled", translate("Telegram Notification"))
o.default = 0
o.rmempty = true

o = s2:option(Value, "telegram_bot_token", translate("Bot Token"))
o.rmempty = true

o = s2:option(Value, "telegram_chat_id", translate("Chat ID"))
o.rmempty = true

o = s2:option(Value, "telegram_api", translate("Telegram API Proxy"))
o.description = translate("Custom API endpoint for Telegram, e.g. api.telegram.org or a proxy like t.me")
o.default = "api.telegram.org"
o.rmempty = true

o = s2:option(Flag, "pushplus_enabled", translate("Pushplus Notification"))
o.default = 0
o.rmempty = true

o = s2:option(Value, "pushplus_token", translate("Pushplus Token"))
o.rmempty = true

return m
