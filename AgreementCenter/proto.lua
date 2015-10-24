-- local skynet = require "skynet"

-- skynet.error("---------------------------------");
-- skynet.error("---------协议定义中心------------");
-- skynet.error("---------------------------------");

local sprotoparser = require "sprotoparser"

local proto = {}

proto.c2s = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

handshake 1 {
	response {
		msg 0  : string
	}
}

quit 2 {}

CreateAccount 3 {
	request {
		username 0 : string
		password 1 : string
	}
	response {
		code 0 : integer
	}
}

UserLogin 4 {
	request {
		username 0 : string
		password 1 : string
	}
	response {
		code 0 : integer
	}
}

PublishRedis 5 {
	request {
		channel 0 : string
		strinfo 1 : string
	}
	response {
		code 0 : integer
	}
}

EnterWordRoom 6 {}

]]

proto.s2c = sprotoparser.parse [[
.package {
	type 0 : integer
	session 1 : integer
}

heartbeat 1 {}

ReturnPublish 2 {
	request {
		strinfo 0 : string
	}
}


]]

return proto
