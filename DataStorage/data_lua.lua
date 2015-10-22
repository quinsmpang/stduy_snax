

local skynet = require "skynet"
require "skynet.manager"	-- import skynet.register

skynet.error("--------------------------");
skynet.error("----------lua db----------");
skynet.error("--------------------------");

--数据存储
local lua_db = {}

--消息指令
local command = {}

function command.GET(key)
	return lua_db[key]
end

function command.SET(key, value)
	local last = lua_db[key]
	lua_db[key] = value
	return last
end

function command.REGISTERED(name, password)
	print("db.name",name)
	print("db.password",password)
	return "success"
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[string.upper(cmd)]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register "SIMPLEDB"
end)
