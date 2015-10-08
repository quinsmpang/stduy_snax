print("--------------------------");
print("---------proto------------");
print("--------------------------");

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

get 2 {
	request {
		what 0 : string
	}
	response {
		result 0 : string
	}
}

set 3 {
	request {
		what 0 : string
		value 1 : string
	}
}

quit 4 {}

CreateAccount 5 {
	request {
		username 0 : string
		password 1 : string
	}
	response {
		code 0 : integer
	}
}

UserLogin 6 {
	request {
		username 0 : string
		password 1 : string
	}
	response {
		code 0 : integer
	}
}


PublishRedis 7 {
	request {
		channel 0 : string
		strinfo 1 : string
	}
	response {
		code 0 : integer
	}
}

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
