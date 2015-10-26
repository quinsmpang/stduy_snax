

local skynet = require "skynet"
local netpack = require "netpack"
local socket = require "socket"
local sproto = require "sproto"
local sprotoloader = require "sprotoloader"
local redis = require "redis"
local profile = require "profile"
local mc = require "multicast"

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
local c2

function send_package(pack)
	local package = string.pack(">s2", pack)
	socket.write(client_fd, package)
end

local function timeCallFuc(nTime)
	
	if nTime > 0 then
		skynet.timeout(3*100, function()
			c2:publish("test:"..tostring(nTime))
			timeCallFuc(nTime-1);
		end)
	end
end


function REQUEST.get()
	print("get", self.what)
	local r = skynet.call("SIMPLEDB", "lua", "get", self.what)
	return { result = r }
end

function REQUEST.set()
	print("set", self.what, self.value)
	local r = skynet.call("SIMPLEDB", "lua", "set", self.what, self.value)
end

function REQUEST:handshake()
	REQUEST:EnterWordRoom();
	return { msg = "Welcome to skynet, I will send heartbeat every 5 sec." }
end

function REQUEST.quit()
	-- skynet.call(WATCHDOG, "lua", "close", client_fd)
	timeCallFuc(3)
end

function woldRoomMsg(str1, str2, str3)
	-- skynet.error("---woldRoomMsg:"..tostring(str1).."_"..tostring(str2).."_"..tostring(str3));
	local str = tostring(skynet:self());
	local retData = send_request("ReturnPublish", {strinfo = str3})
	send_package(retData);
end

---------------------------------------
function REQUEST.EnterWordRoom()
	print("agent EnterWordRoom")
	local roomInfo = skynet.call("CHATROOM", "lua", "enterRoom", "WorldRoom")
	
	--
	c2 = mc.new {
		channel = roomInfo.channelId,  -- 绑定上一个频道
		-- dispatch = function (channel, source, ...) return,  -- 设置这个频道的消息处理函数
		dispatch = woldRoomMsg;
	}
	--]]
	c2:subscribe();
	c2:publish("test")
end



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

local function message_dispatch(name, args, response)
	
	-- profile.resume()
	profile.start()
	

	local f = assert(REQUEST[name])	
	local r = f(args)
	if response then
		local ret =  response(r);
		local times = profile.stop()
		skynet.error(string.format("end, pass it to serviceAgent :%s", times))
		return ret;
	else
		local times = profile.stop()
		skynet.error(string.format("end, pass it to serviceAgent :%s", times))
	end
end


skynet.register_protocol {
	name = "client",
	id = skynet.PTYPE_CLIENT,
	unpack = function (msg, sz)
		return host:dispatch(msg, sz)
	end,
	dispatch = function (_, _, type, ...)
		if type == "REQUEST" then
			local ok, result  = pcall(message_dispatch, ...)
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
