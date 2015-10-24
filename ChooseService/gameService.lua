
-- 游戏选服列表服务
-- 一个Http服务,用于选服列表

local skynet = require "skynet"
local socket = require "socket"
local profile = require "profile"
local string = string

--是否开启限制Http选服服务个数
local isOpenLimitAgent = false
local limitAgentNum = 20;


skynet.start(function()
	
	local balance = 1
	local serviceAgent = {};	
	if isOpenLimitAgent then
		for i= 1, limitAgentNum do
			serviceAgent[i] = skynet.newservice("serviceAgent");
		end
	end
	
	profile.start()
	skynet.error("-----------------------------")
	skynet.error("----监听游戏Http:8001端口----")
	local times = profile.stop()
	skynet.error("----监听游戏Http:8001端口----",times)
	
	local id = socket.listen("0.0.0.0", 8001)
	socket.start(id , function(id, addr)
		
		
		if isOpenLimitAgent then
			skynet.error(string.format("%s connected, pass it to serviceAgent :%08x", addr, serviceAgent[balance]))
			skynet.send(serviceAgent[balance], "lua", id, false);
			balance = balance + 1
			if balance > #serviceAgent then
				balance = 1
			end
		else
			local Agent = skynet.newservice("serviceAgent");
			skynet.error(string.format("%s connected, pass it to serviceAgent :%08x", addr, Agent))
			skynet.send(Agent, "lua", id, true);
		end
	end)
end)
