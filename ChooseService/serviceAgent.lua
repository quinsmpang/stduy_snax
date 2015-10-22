
-- 游戏选服列表服务
-- 一个Http服务,用于选服列表

local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local table = table
local string = string



local function response(id, ...)
	skynet.error("----------");
	local ok, err = httpd.write_response(sockethelper.writefunc(id), ...)
	if not ok then
		-- if err == sockethelper.socket_error , that means socket closed.
		skynet.error(string.format("fd = %d, %s", id, err))
	end
end

local function getServiceList()

	skynet.error("---------getServiceList-----------");
	local strService = "";
	local outIndex = 0;
	local r = skynet.call("MYSQLITEDB", "lua", "getOneTable", "ServiceList")
	for k,v in pairs(r) do

		local intIndex = 0;
		local newService = "";
		for key,value in pairs(v) do
			if intIndex == 0 then
				newService = tostring(key).."="..tostring(value);
			else
				newService = newService..","..tostring(key).."="..tostring(value);
			end
			intIndex = intIndex + 1;
		end
		if outIndex == 0 then
			strService = newService;
		else
			strService = strService.."\n"..newService;
		end
		outIndex = outIndex + 1;
	end
	
	return strService;
end


skynet.start(function()
	skynet.dispatch("lua", function (_,_,id)
		socket.start(id)
		-- limit request body size to 8192 (you can pass nil to unlimit)
		local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
		--[[
		skynet.error("***********");
		skynet.error(code)
		skynet.error(url)
		skynet.error(method)
		skynet.error(header)
		skynet.error("------------")
		for k, v in pairs(header) do
			local str = "key="..tostring(k).." value="..tostring(v)
			skynet.error(str);
		end
		skynet.error("------------")
		skynet.error(body);
		skynet.error("***********");
		--]]
		if code then
			if code ~= 200 then
				response(id, code)
			else
				--[[
				local tmp = {}
				if header.host then
					table.insert(tmp, string.format("host: %s", header.host))
				end
				local path, query = urllib.parse(url)
				table.insert(tmp, string.format("path: %s", path))
				if query then
					local q = urllib.parse_query(query)
					for k, v in pairs(q) do
						table.insert(tmp, string.format("query: %s= %s", k,v))
					end
				end
				table.insert(tmp, "-----header----")
				for k,v in pairs(header) do
					table.insert(tmp, string.format("%s = %s",k,v))
				end
				table.insert(tmp, "-----body----\n" .. body)
				--]]
				-- response(id, code, table.concat(tmp,"\n"))
				response(id, code, getServiceList())
			end
		else
			if url == sockethelper.socket_error then
				skynet.error("socket closed")
			else
				skynet.error(url)
			end
		end
		socket.close(id)
		
		skynet.exit()
	end)
end)

