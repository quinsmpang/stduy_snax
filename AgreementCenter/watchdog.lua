--[[
所有网络连接都会被这个脚本监听
--]]


local skynet = require "skynet"
local netpack = require "netpack"

skynet.error("----------------------------------");
skynet.error("---------网络连接监听中心---------");
skynet.error("----------------------------------");

local CMD = {}
local SOCKET = {}
local gate
local agent = {}
local nowClient = 0;

function SOCKET.open(fd, addr)

	skynet.error("New client from : " .. addr)
	
	agent[fd] = skynet.newservice("agent")
	skynet.call(agent[fd], "lua", "start", { gate = gate, client = fd, watchdog = skynet.self() })
	
	nowClient = nowClient + 1;
	skynet.error("nowClient : " .. nowClient)
	
end

local function close_agent(fd)
	local a = agent[fd]
	agent[fd] = nil
	if a then
		skynet.call(gate, "lua", "kick", fd)
		-- disconnect never return
		skynet.send(a, "lua", "disconnect")
	end
end

function SOCKET.close(fd)
	print("socket close",fd)
	close_agent(fd)
	nowClient = nowClient - 1;
	skynet.error("nowClient : " .. nowClient)
end

function SOCKET.error(fd, msg)
	print("socket error",fd, msg)
	close_agent(fd)
end

function SOCKET.data(fd, msg)
end

function CMD.start(conf)
	skynet.call(gate, "lua", "open" , conf)
end

function CMD.close(fd)
	close_agent(fd)
end

skynet.start(function()
	skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
		if cmd == "socket" then
			local f = SOCKET[subcmd]
			f(...)
			-- socket api don't need return
		else
			local f = assert(CMD[cmd])
			skynet.ret(skynet.pack(f(subcmd, ...)))
		end
	end)

	gate = skynet.newservice("gate")
end)
