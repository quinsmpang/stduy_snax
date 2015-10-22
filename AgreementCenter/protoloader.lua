

-- module proto as examples/proto.lua
package.path = "./stduy_snax/AgreementCenter/?.lua;" .. package.path

local skynet = require "skynet"
local sprotoparser = require "sprotoparser"
local sprotoloader = require "sprotoloader"
local proto = require "proto"

skynet.error("---------------------------------");
skynet.error("---------协议预加载中心----------");
skynet.error("---------------------------------");

skynet.start(function()
	sprotoloader.save(proto.c2s, 1)
	sprotoloader.save(proto.s2c, 2)
	-- don't call skynet.exit() , because sproto.core may unload and the global slot become invalid
end)
