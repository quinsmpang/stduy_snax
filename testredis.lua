print("--------------------------");
print("----------redis-----------");
print("--------------------------");

local skynet = require "skynet"
local redis = require "redis"
require "skynet.manager"	-- import skynet.register

local conf = {
	host = "127.0.0.1" ,
	port = 6379 ,
	db = 0
}

local dbRedis = nil;


local command = {}
function command.GET(key)
	return db[key]
end

function command.SET(key, value)
	local last = db[key]
	db[key] = value
	return last
end

function command.REGISTERED(name, password)
	return "success"
end

-------------------------------------------
--set get del exit
function redis_test_1()
	print("-------------redis_test_1-----------");
	if dbRedis:setnx("myTestKey", "12121") == 1 then
		print("set date:");
	end
	if not dbRedis:exists("myTestKey") then
		dbRedis:set("myTestKey", "myData");
		local data= dbRedis:get("myTestKey")
		print("set date:",data);
	else
		local data= dbRedis:get("myTestKey")
		print("del date:",data);
		dbRedis:del("myTestKey")
	end
	
	dbRedis:set("myTestKey1", {"myData"});
	local tdata = dbRedis:get("myTestKey1");
	for k,v in pairs(tdata) do
		print("--"..k)
	end
	
	dbRedis:mset("fruit", "apple","drink", "beer", "food", "cookies")
	
	print(dbRedis:get("fruit"))
	print(dbRedis:get("drink"))
	print(dbRedis:get("food"))
	
	dbRedis:hmset("website", "google", "www.google.com", "yahoo", "www.yahoo.com")
	print(dbRedis:hget("website", "yahoo"));
	
end

local function watching()
	local w = redis.watch(conf)
	w:subscribe "foo"
	-- w:psubscribe "hello.*"
	w:psubscribe "foo"
	while true do
		print("Watch", w:message())
	end
end

------------------------------------------

--======================================--
skynet.start(function()
	
	skynet.fork(watching)
	dbRedis = redis.connect(conf);
	if not dbRedis then
		print("*******************************")
		print("*******Redis Connet Fail*******")
		print("*******************************")
		skynet.exit();
	end

	redis_test_1();

	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[string.upper(cmd)]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register "MYREDISDB";
	
	--[[
	if db then
		db:del "C"
		db:set("A", "hello")
		db:set("B", "world")
		db:sadd("C", "one")

		print(db:get("A"))
		print(db:get("B"))

		db:del "D"
		for i=1,10 do
			db:hset("D",i,i)
		end
		local r = db:hvals "D"
		for k,v in pairs(r) do
			print(k,v)
		end

		db:multi()
		db:get "A"
		db:get "B"
		local t = db:exec()
		for k,v in ipairs(t) do
			print("Exec", v)
		end

		print(db:exists "A")
		print(db:get "A")
		print(db:set("A","hello world"))
		print(db:get("A"))
		print(db:sismember("C","one"))
		print(db:sismember("C","two"))

		print("===========publish============")
		for i=1,10 do
			db:publish("foo", i)
		end
		for i=11,20 do
			db:publish("hello.foo", i)
		end
		db:disconnect()
	else
		print("redis connect failed");
	end
	--]]
end)

