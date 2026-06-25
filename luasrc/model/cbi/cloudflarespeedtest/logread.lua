local m = Map("cloudflarespeedtest")
m.title = translate("Cloudflare Speed Test Logs")
m.reset = false
m.submit = false

local s = m:section(SimpleSection)
s.template = "cloudflarespeedtest/logread"

return m
