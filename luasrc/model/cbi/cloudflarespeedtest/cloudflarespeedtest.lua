require("luci.sys")

m = Map("cloudflarespeedtest")
m.title = translate("Cloudflare Speed Test")
m.description = '<a href="https://github.com/XIU2/CloudflareSpeedTest" target="_blank">CloudflareSpeedTest</a>'

-- [[ Basic Settings ]] --

s = m:section(NamedSection, "global")
s.addremove = false
s.anonymous = true

o = s:option(Flag, "enabled", translate("Scheduled Task"))
o.description = translate("Enable daily scheduled speed test (cron job)")
o.rmempty = false
o.default = 0

o = s:option(Flag, "ipv6_enabled", translate("IPv6 Mode"))
o.description = translate("Enable IPv6 speed test (IPv4 will not be tested)")
o.default = 0
o.rmempty = false

o = s:option(Value, "speed", translate("Bandwidth (Mbps)"))
o.description = translate("Your broadband speed in Mbps. E.g. 100M broadband = 100")
o.datatype = "uinteger"
o.rmempty = false
o.default = 100

o = s:option(Value, "custome_url", translate("Speed Test URL"))
o.description = translate("Custom download test URL")
o.rmempty = false
o.default = "https://cloudflaremirrors.com/oracle/OL9/u1/x86_64/OracleLinux-R9-U1-x86_64-dvd.iso"

o = s:option(Flag, "custome_cors_enabled", translate("Custom Cron"))
o.description = translate("Enable custom cron expression")
o.default = 0
o.rmempty = false

o = s:option(Value, "custome_cron", translate("Cron Expression"))
o:depends("custome_cors_enabled", 1)
o.placeholder = "0 5 * * *"

hour = s:option(Value, "hour", translate("Hour"))
hour.datatype = "range(0,23)"
hour:depends("custome_cors_enabled", 0)
hour.default = 5

minute = s:option(Value, "minute", translate("Minute"))
minute.datatype = "range(0,59)"
minute:depends("custome_cors_enabled", 0)
minute.default = 0

o = s:option(ListValue, "proxy_mode", translate("Proxy Plugins"))
o:value("nil", translate("Keep Current"))
o:value("close", translate("Disable During Test"))
o.default = "nil"
o.description = translate("Temporarily disable all proxy plugins during speed test, auto restore after")

o = s:option(Flag, "advanced", translate("Advanced Settings"))
o.description = translate("Show advanced speed test parameters")
o.default = 0
o.rmempty = false

-- [[ Advanced: Latency Test ]] --

o = s:option(Value, "threads", translate("Threads"))
o.description = translate("Number of concurrent threads for latency test (1-1000)")
o.datatype = "range(1,1000)"
o.default = 100
o.rmempty = true
o:depends("advanced", 1)

o = s:option(Value, "t", translate("Test Count"))
o.description = translate("Number of latency tests per IP")
o.datatype = "uinteger"
o.default = 4
o.rmempty = true
o:depends("advanced", 1)

o = s:option(Value, "tp", translate("Port"))
o.description = translate("Port for latency/download test (default: 443)")
o.rmempty = true
o.default = 443
o.datatype = "port"
o:depends("advanced", 1)

o = s:option(ListValue, "httping", translate("HTTPing Mode"))
o:value("0", translate("TCPing (default)"))
o:value("1", translate("HTTPing"))
o.description = translate("HTTPing mode can get region code but may be detected as scanning")
o.default = "0"
o:depends("advanced", 1)

o = s:option(Value, "httping_code", translate("HTTPing Valid Code"))
o.description = translate("Valid HTTP status code for HTTPing test (e.g. 200,301,302)")
o.default = "200"
o.rmempty = true
o:depends("httping", "1")

o = s:option(Value, "cfcolo", translate("Region Filter"))
o.description = translate("IATA airport codes, comma separated. E.g. HKG,LAX,NRT (HTTPing only)")
o.rmempty = true
o:depends("httping", "1")

-- [[ Advanced: Filter ]] --

o = s:option(Value, "tl", translate("Avg Latency Upper (ms)"))
o.description = translate("Only output IPs with average latency below this value")
o.datatype = "uinteger"
o.default = 200
o.rmempty = true
o:depends("advanced", 1)

o = s:option(Value, "tll", translate("Avg Latency Lower (ms)"))
o.description = translate("Only output IPs with average latency above this value")
o.datatype = "uinteger"
o.default = 40
o.rmempty = true
o:depends("advanced", 1)

o = s:option(Value, "tlr", translate("Packet Loss Upper"))
o.description = translate("Only output IPs with packet loss below this rate (0.00-1.00, 0=no loss)")
o.datatype = "range(0.00,1.00)"
o.default = "1.00"
o.rmempty = true
o:depends("advanced", 1)

-- [[ Advanced: Download Test ]] --

o = s:option(Value, "dn", translate("Download Count"))
o.description = translate("Number of IPs to download test after latency sort")
o.datatype = "uinteger"
o.default = 1
o.rmempty = true
o:depends("advanced", 1)

o = s:option(Value, "dt", translate("Download Timeout (s)"))
o.description = translate("Max download test time per IP in seconds")
o.datatype = "uinteger"
o.default = 10
o.rmempty = true
o:depends("advanced", 1)

o = s:option(Value, "sl", translate("Download Speed Lower (MB/s)"))
o.description = translate("Only output IPs with download speed above this value (0=no limit)")
o.datatype = "float"
o.default = "0"
o.rmempty = true
o:depends("advanced", 1)

o = s:option(Flag, "dd", translate("Disable Download Test"))
o.description = translate("Only do latency test, sort by latency")
o.default = 0
o.rmempty = true
o:depends("advanced", 1)

-- [[ Advanced: Other ]] --

o = s:option(Value, "p", translate("Display Count"))
o.description = translate("Number of results to display (0=no display)")
o.datatype = "uinteger"
o.default = 5
o.rmempty = true
o:depends("advanced", 1)

o = s:option(Flag, "allip", translate("Test All IPs"))
o.description = translate("Test every IP in the range instead of random one per /24 (IPv4 only)")
o.default = 0
o.rmempty = true
o:depends("advanced", 1)

o = s:option(Flag, "debug", translate("Debug Mode"))
o.description = translate("Show detailed error messages during test")
o.default = 0
o.rmempty = true
o:depends("advanced", 1)

o = s:option(Value, "ip_data", translate("Custom IP Data"))
o.description = translate("Specify IP ranges directly, comma separated. E.g. 1.1.1.1,2.2.2.2/24")
o.rmempty = true
o:depends("advanced", 1)

-- [[ Action Buttons ]] --

o = s:option(DummyValue, "", "")
o.rawhtml = true
o.template = "cloudflarespeedtest/actions"

-- [[ Best IP Display ]] --

e = m:section(TypedSection, "global", translate("Best IP"))
e.anonymous = true
local a = "/usr/share/cloudflarespeedtestresult.txt"
tvIPs = e:option(TextValue, "syipstext")
tvIPs.rows = 12
tvIPs.readonly = "readonly"
tvIPs.wrap = "off"

function tvIPs.cfgvalue(e, e)
	sylogtext = ""
	if a and nixio.fs.access(a) then
		sylogtext = luci.sys.exec("cat %s 2>/dev/null" % a)
	end
	return sylogtext
end

tvIPs.write = function(e, e, e)
end

m.on_after_commit = function(self)
	luci.sys.call("/etc/init.d/cloudflarespeedtest reload >/dev/null 2>&1 &")
end

return m
