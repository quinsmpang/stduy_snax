print("--------------------------");
print("----------mian------------");
print("--------------------------");

local skynet = require "skynet"
local sprotoloader = require "sprotoloader"

local max_client = 64

skynet.start(function()
	print("Server start")
	
	skynet.uniqueservice("protoloader")
	-- local console = skynet.newservice("console")
	-- skynet.newservice("debug_console",8000)
	
	--游戏Http选服列表服务
	skynet.newservice("gameService");
	
	--数据存储服务
	skynet.newservice("data_lua");
	skynet.newservice("data_redis");
	-- skynet.newservice("data_mysql")
	
	local watchdog = skynet.newservice("watchdog")
	skynet.call(watchdog, "lua", "start", {
		port = 8888,
		maxclient = max_client,
		nodelay = true,
	})
	print("Watchdog listen on ", 8888)

	skynet.exit()
end)
