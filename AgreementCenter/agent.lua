

local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local redis = require "redis"

skynet.error("-----------------------------------");
skynet.error("-----------消息分发中心------------");
skynet.error("-----------------------------------");


local WATCHDOG
local host
local send_request

local CMD = {}
local REQUEST = {}
local client_fd
local watch
local usernameinfo

function REQUEST:get()
	print("get", self.what)
	local r = skynet.call("SIMPLEDB", "lua", "get", self.what)
	return { result = r }
end

function REQUEST:set()
	print("set", self.what, self.value)
	local r = skynet.call("SIMPLEDB", "lua", "set", self.what, self.value)
end

function REQUEST:handshake()
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST:quit()
	skynet.call(WATCHDOG, "lua", "close", client_fd)
end

---------------------------------------
--账号创建
function REQUEST:CreateAccount()
	usernameinfo = self.username;
	
	local ret = skynet.call("MYREDISDB", "lua", "CreateAccount", self.username, self.password)
	if ret then
		return { code = 0 };
	end
	return { code = 1 };
end

--账号登陆
function REQUEST:UserLogin()

end

--推送Redis消息
function REQUEST:PublishRedis()
	print("PublishRedis login:",usernameinfo);
	local ret = skynet.call("MYREDISDB", "lua", "PublishRedis", self.channel, self.strinfo)
	if ret then
		return { code = 0 };
	end
	return { code = 1 };
end

local function request(name, args, response)
	local f = assert(REQUEST[name])
	local r = f(args)
	if response then
		return response(r)
	end
end

local function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (_, _, type, ...)
		if type == "REQUEST" then
			local ok, result  = pcall(request, ...)
			if ok then
				if result then
					send_package(result)
				end
			else
				skynet.error(result)
			end
		else
			assert(type == "RESPONSE")
			error "This example doesn't support request client"
		end
	end
}

function CMD.start(conf)
	local fd = conf.client
	local gate = conf.gate
	WATCHDOG = conf.watchdog
	-- slot 1,2 set at main.lua
	host = sprotoloader.load(1):host "package"
	send_request = host:attach(sprotoloader.load(2))
	
	--订阅redis消息
	watch = redis.watch({host = "127.0.0.1" ,port = 6379 ,db = 0})
	watch:psubscribe("chat");
	
	skynet.fork(function()
		while true do
			-- send_package(send_request "heartbeat")
			-- skynet.sleep(500)
			
			local data = watch:message();
			skynet.error("Watch", skynet.self(), data)
			local retData = send_request("ReturnPublish", {strinfo = data})
			send_package(retData);
		end
	end)

	client_fd = fd
	skynet.call(gate, "lua", "forward", fd)
end

function CMD.disconnect()
	-- todo: do something before exit
	skynet.exit()
end

skynet.start(function()
	skynet.dispatch("lua", function(_,_, command, ...)
		local f = CMD[command]
		skynet.ret(skynet.pack(f(...)))
	end)
end)
