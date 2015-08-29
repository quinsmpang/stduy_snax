print("--------------------------");
print("---------client-----------");
print("--------------------------");

package.cpath = "luaclib/?.so"
package.path = "lualib/?.lua;examples/stduy_snax/?.lua"

if _VERSION ~= "Lua 5.3" then
	error "Use lua 5.3"
end

local socket = require "clientsocket"
local proto = require "proto"
local sproto = require "sproto"

local host = sproto.new(proto.s2c):host "package"
local request = host:attach(sproto.new(proto.c2s))


--------------------------------------------
local function send_package(fd, pack)
	local package = string.pack(">s2", pack)
	socket.send(fd, package)
end

local function unpack_package(text)
	local size = #text
	if size < 2 then
		return nil, text
	end
	local s = text:byte(1) * 256 + text:byte(2)
	if size < s+2 then
		return nil, text
	end

	return text:sub(3,2+s), text:sub(3+s)
end

local function recv_package(fd, last)
	local result
	result, last = unpack_package(last)
	if result then
		return result, last
	end
	local r = socket.recv(fd)
	if not r then
		return nil, last
	end
	if r == "" then
		error "Server closed"
	end
	return unpack_package(last .. r)
end

local function send_request(tClient, name, args)
	tClient.session = tClient.session + 1
	local str = request(name, args, tClient.session)
	send_package(tClient.fd, str)
	print("Request:", tClient.session)
end

---------------------------------------------------
local function print_request(name, args)
	print("REQUEST", name)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

local function print_response(session, args)
	print("RESPONSE", session)
	if args then
		for k,v in pairs(args) do
			print(k,v)
		end
	end
end

local function print_package(t, ...)
	if t == "REQUEST" then
		print_request(...)
	else
		assert(t == "RESPONSE")
		print_response(...)
	end
end


local function createClient()
	local tClient = {};
	
	tClient.socket = require "clientsocket"
	tClient.proto  = require "proto"
	tClient.sproto = require "sproto"

	tClient.fd = assert(tClient.socket.connect("127.0.0.1", 8888))
	tClient.last = "";
	tClient.session = 0;
	tClient.host = tClient.sproto.new(tClient.proto.s2c):host "package"
	tClient.request = tClient.host:attach(tClient.sproto.new(tClient.proto.c2s))	
	
	
	function tClient.send_package(fd, pack)
		local package = string.pack(">s2", pack)
		tClient.socket.send(fd, package)
	end

	function tClient.unpack_package(text)
		local size = #text
		if size < 2 then
			return nil, text
		end
		local s = text:byte(1) * 256 + text:byte(2)
		if size < s+2 then
			return nil, text
		end

		return text:sub(3,2+s), text:sub(3+s)
	end

	function tClient.recv_package()
		local result
		result, tClient.last = tClient.unpack_package(tClient.last)
		if result then
			return result, tClient.last
		end
		local r = tClient.socket.recv(tClient.fd)
		if not r then
			return nil, tClient.last
		end
		if r == "" then
			error "Server closed"
		end
		return tClient.unpack_package(tClient.last .. r)
	end

	function tClient.send_request(name, args)
		tClient.session = tClient.session + 1
		local str = tClient.request(name, args, tClient.session)
		send_package(tClient.fd, str)
		print("Request:", tClient.session)
	end

	---------------------------------
	function tClient.print_request(name, args)
		print("REQUEST", name)
		if args then
			for k,v in pairs(args) do
				print(k,v)
			end
		end
	end

	function tClient.print_response(session, args)
		print("RESPONSE", session)
		if args then
			for k,v in pairs(args) do
				print(k,v)
			end
		end
	end
	
	return tClient;
end


local clientTb = {};
for i = 1, 4 do
	local tClient = {};
	local tc = createClient()
	table.insert(clientTb,tc);
	tc.send_request("handshake");
	
end

local function dispatch_package()
	for i, d in ipairs(clientTb) do
		
		while true do
			local v
			v, d.last = d.recv_package()
			if not v then
				break
			end
			-- print("------------------------")
			-- for i=1,#v do
				-- print(v:byte(i));
			-- end
			-- print("------------------------")
			print_package(d.host:dispatch(v))
		end		
		d.socket.usleep(10000)
	end
end

-- send_request("registered", { name = "ccmfeng", password = "chenglijie" })

while true do
	dispatch_package()
	--[[
	local cmd = socket.readstdin()
	if cmd then
		
		if cmd == "quit" then
			send_request("quit")
		else
			send_request("get", { what = cmd })
		end
	else
		
		socket.usleep(10000)
		
	end
	--]]
	
end
