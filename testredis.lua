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


--Redis�������л�
function serialize(t)
	local mark={}
	local assign={}
	
	local function ser_table(tbl,parent)
		mark[tbl]=parent
		local tmp={}
		for k,v in pairs(tbl) do
			print("key:"..k)
			local key= type(k)=="number" and "["..k.."]" or k
			
			if type(v)=="table" then
				local dotkey= parent..(type(k)=="number" and key or "."..key)
				if mark[v] then
					table.insert(assign,dotkey.."="..mark[v])
				else
					table.insert(tmp, key.."="..ser_table(v,dotkey))
				end
			elseif type(v) == "string" then
				table.insert(tmp, key.."=\""..v.."\"");
			elseif type(v) == "number" then	
				table.insert(tmp, key.."="..v)
			else
				if v then
					table.insert(tmp, key.."=true")
				else
					table.insert(tmp, key.."=false")
				end
			end
		end
		return "{"..table.concat(tmp,",").."}"
	end
	-- return "do local ret="..ser_table(t,"ret")..table.concat(assign," ").." return ret end"
	return ser_table(t,"ret")..table.concat(assign," ");
end

--Redis���ݷ����л�
function deserialization(str)
	local serStr = "do local ret="..tostring(str).." return ret end"
	local tb = load(serStr)();
	return tb;
end


local command = {}

-- �����˺�
function command.CreateAccount(userName, passWord)
	--�ж��˺��û����Ƿ��Ѿ�����
	print("Redis:CreateAccount", userName, passWord)
	if userName ~= nil and userName ~= "" then
		local strAccountKey = "Account:"..userName;
		if not dbRedis:exists(strAccountKey) then
			local entityID = dbRedis:incr("AccountIndex");
			local tUserInfo = {entityID,userName, passWord};
			local tStrInfo  = serialize(tUserInfo);
			dbRedis:set(strAccountKey, tStrInfo)
			return true;
		-- else
			-- local str = dbRedis:get(userName);
			-- print(str);
			-- local tUserInfo = deserialization(str);
			-- print("EntityId", tUserInfo[1]);
		end
	end
	return false;
end



-------------------------------------------
--��ʽ����
function redis_init()

	if not dbRedis:exists("AccountIndex") then
		--�û�ʵ��ID��ʼ�±��趨
		dbRedis:set("AccountIndex", 1);
	end
	
	
	

end

-------------------------------------------

--��ͨ
function redis_key_1()
	--������Key����
	print("-------------redis_key_1-----------");
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
	
	dbRedis:mset("fruit", "apple","drink", "beer", "food", "cookies")
	print(dbRedis:get("fruit"))
	print(dbRedis:get("drink"))
	print(dbRedis:get("food"))
	print("-------key---------")
	
	local tb = dbRedis:keys("*");
	for k, v in ipairs(tb) do
		print(k.."-"..v)
	end
	
	dbRedis:hmset("website", "google", "www.google.com", "yahoo", "www.yahoo.com")
	print(dbRedis:hget("website", "yahoo"));
	
end

-- ��ϣ��
function redis_hash_2()
	
end

--�б�
function redis_list_3()
	--�������
	print("-------list-----------")
	-- print(dbRedis:lpush("languages","C++"));
	-- print(dbRedis:lpush("languages","python"));
	-- print(dbRedis:lpush("languages","Java"));
	
	print(dbRedis:llen("languages"));
	local listData = dbRedis:lrange("languages",0,2)
	for k,v in ipairs(listData) do
		print(v);
	end
	
end

--redis����
function redis_set_4()
	--���ϲ���
	print("-------set-----------")
	-- �������������
	dbRedis:sadd("bbs", "tianya.cn", "groups.google.com");
	
	-- �Ƴ�Ԫ��
	print(dbRedis:srem("bbs", "groups.google.com"));
	
	-- ��ȡ��������
	local tbData = dbRedis:smembers("bbs")
	for k,v in ipairs(tbData) do
		print(k.."-"..v);
	end
		
	-- �жϼ����Ƿ����Ԫ��
	if dbRedis:sismember("bbs", "tianya.cn") then
		print("have node");
	end
end

--redis���򼯺�
function redis_sortset_5()
	--���ϲ���
	print("-------sortset-----------")
	-- �������������
	print(dbRedis:zadd("page_rank", 9 ,"baidu.com", 8,"bing.com"));
	
	--��ĳ��Keyֵ��ӷ�ֵ
	print(dbRedis:zincrby("page_rank", 100 ,"bing.com"));
	
	--��ȡĳ��Key�ķ�ֵ
	print(dbRedis:zscore("page_rank", "bing.com"));
	
	-- ������ɾ������
	print(dbRedis:zrem("page_rank", "baidu.com"));
	
	
end



--redis�����л�
function redis_ser()
	local tb = {1,2,3,"hello", true};
	--���л�Lua��
	local tbData = serialize(tb);
	print("���л�:"..tbData)
	dbRedis:set("ser", tbData);
	local serStr = dbRedis:get("ser");
	print(serStr);
	--�����л�Lua������
	print("------------------")
	-- local tb = load(serStr)();
	local tb = deserialization(serStr)
	for k,v in pairs(tb) do
		if type(v) == "boolean" then
			print("key=---"..tostring(v));
		end
		print("key=",k,"  value=",v)
	end
	print("------------------")
	
	
	local tb2 = {};
	tb2["key1"] = 1;
	tb2["key2"] = 2;
	tb2["key3"] = "dsad";
	tb2["key4"] = true;
	--���л�Lua��
	local tbData = serialize(tb2);
	print("���л�2:"..tbData)
	dbRedis:set("ser2", tbData);
	local serStr = dbRedis:get("ser2");
	print(serStr);
	--�����л�Lua������
	print("------------------")
	-- local tb = load(serStr)();
	local tb = deserialization(serStr)
	for k,v in pairs(tb) do
		if type(v) == "boolean" then
			print("key=---"..tostring(v));
		end
		print("key=",k,"  value=",v)
	end
	print("------------------")
	
end

function redis_test()
	local db = dbRedis
	db:del "C"
	db:set("B:2", "hello")
	db:set("B:1", "world")
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
end

--ʵ��ID
function redis_entityID()

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

--======================================--
skynet.start(function()
	
	-- skynet.fork(watching)
	dbRedis = redis.connect(conf);
	if not dbRedis then
		print("*******************************")
		print("*******Redis Connet Fail*******")
		print("*******************************")
		skynet.exit();
	end
	redis_init();
	redis_key_1();
	--[[
	redis_test();
	redis_key_1();
	redis_list_2();
	redis_set_3();
	redis_ser();
	redis_entityID();
	--]]
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[cmd]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register "MYREDISDB";
	
end)

