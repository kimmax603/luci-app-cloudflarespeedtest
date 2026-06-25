module("luci.controller.cloudflarespeedtest", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/cloudflarespeedtest") then
		return
	end

	local page
	page = entry({"admin", "services", "cloudflarespeedtest"}, firstchild(), _("Cloudflare Speed Test"), 99)
	page.dependent = false
	page.acl_depends = {"luci-app-cloudflarespeedtest"}

	entry({"admin", "services", "cloudflarespeedtest", "general"}, cbi("cloudflarespeedtest/cloudflarespeedtest"), _("Basic Settings"), 1)
	entry({"admin", "services", "cloudflarespeedtest", "dns"}, cbi("cloudflarespeedtest/cf_dns"), _("Cloudflare DNS"), 2)
	entry({"admin", "services", "cloudflarespeedtest", "logread"}, cbi("cloudflarespeedtest/logread"), _("Logs"), 3)

	entry({"admin", "services", "cloudflarespeedtest", "status"}, call("act_status")).leaf = true
	entry({"admin", "services", "cloudflarespeedtest", "stop"}, call("act_stop"))
	entry({"admin", "services", "cloudflarespeedtest", "start"}, call("act_start"))
	entry({"admin", "services", "cloudflarespeedtest", "getlog"}, call("get_log"))
	entry({"admin", "services", "cloudflarespeedtest", "clearlog"}, call("act_clearlog"))
	entry({"admin", "services", "cloudflarespeedtest", "getiplist"}, call("act_get_iplist"))
	entry({"admin", "services", "cloudflarespeedtest", "saveiplist"}, call("act_save_iplist"))
	entry({"admin", "services", "cloudflarespeedtest", "updateiplist"}, call("act_update_iplist"))
end

function act_status()
	local e = {}
	e.running = luci.sys.call("pgrep -f cloudflarespeedtest >/dev/null") == 0
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function act_stop()
	luci.sys.call("pgrep -f cloudflarespeedtest.sh | xargs kill -9 2>/dev/null")
	luci.sys.call("pgrep -x cfst | xargs kill -9 2>/dev/null")
	luci.http.write("")
end

function act_start()
	act_stop()
	luci.sys.call("/usr/bin/cloudflarespeedtest/cloudflarespeedtest.sh start &")
	luci.http.write("")
end

function get_log()
	local fs = require "nixio.fs"
	-- Read last 100 lines for speed
	local raw = luci.sys.exec("tail -n 100 /var/log/cloudflarespeedtest.log 2>/dev/null") or ""
	-- Filter: remove progress bars (lines with [...])
	local filtered = ""
	for line in raw:gmatch("([^\n]+)") do
		if not line:match("%[.*%]") and line:match("%S") then
			filtered = filtered .. line .. "\n"
		end
	end
	luci.http.prepare_content("text/plain; charset=utf-8")
	luci.http.write(filtered)
end

function act_clearlog()
	luci.sys.call("> /var/log/cloudflarespeedtest.log")
	luci.http.prepare_content("application/json")
	luci.http.write_json({ok = true})
end

function act_get_iplist()
	local fs = require "nixio.fs"
	local e = {}
	e.ipv4 = fs.readfile("/usr/share/CloudflareSpeedTest/ip.txt") or ""
	e.ipv6 = fs.readfile("/usr/share/CloudflareSpeedTest/ipv6.txt") or ""
	luci.http.prepare_content("application/json")
	luci.http.write_json(e)
end

function act_save_iplist()
	local content = luci.http.formvalue("content") or ""
	local ip_type = luci.http.formvalue("type") or "ipv4"
	local fs = require "nixio.fs"

	if ip_type == "ipv6" then
		fs.writefile("/usr/share/CloudflareSpeedTest/ipv6.txt", content)
	else
		fs.writefile("/usr/share/CloudflareSpeedTest/ip.txt", content)
	end

	luci.http.prepare_content("application/json")
	luci.http.write_json({ok = true})
end

function act_update_iplist()
	luci.sys.call("/usr/bin/cloudflarespeedtest/cloudflarespeedtest.sh updateiplist")
	luci.http.prepare_content("application/json")
	luci.http.write_json({ok = true})
end
