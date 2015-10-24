--[[

--]]

require "skynet.manager"	-- import skynet.register
local skynet = require "skynet"
local netpack = require "netpack"

local mc = require "multicast"

local command = {}

--房间存储器
local roomList = {};

function command.enterRoom(roomName)
	
	
	local roomInfo = roomList[tostring(roomName)];
	if roomInfo == nil then
		
		skynet.error(string.format("---------enterRoom %s", tostring(roomName)));
		
		-- 创建一个频道，成功创建后，.channel 是这个频道的 id 。
		local channel = mc.new()
		--[[
		local c2 = mc.new {
			channel = channel.channel,  -- 绑定上一个频道
			dispatch = function (channel, source, ...) return,  -- 设置这个频道的消息处理函数
		}
		--]]
		roomInfo = {name = roomName, channelId = channel.channel}
		roomList[tostring(roomName)] = roomInfo;
	end
	
	return roomInfo;
	
end

skynet.start(function()
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register "CHATROOM";
end)
