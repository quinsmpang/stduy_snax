--


local skynet = require "skynet"
local mysql = require "mysql"
require "skynet.manager"	-- import skynet.register

skynet.error("-------------------------------");
skynet.error("----------data_mysql-----------");
skynet.error("-------------------------------");

local sqldb = nil;

local function dump(obj)
    local getIndent, quoteStr, wrapKey, wrapVal, dumpObj
    getIndent = function(level)
        return string.rep("\t", level)
    end
    quoteStr = function(str)
        return '"' .. string.gsub(str, '"', '\\"') .. '"'
    end
    wrapKey = function(val)
        if type(val) == "number" then
            return "[" .. val .. "]"
        elseif type(val) == "string" then
            return "[" .. quoteStr(val) .. "]"
        else
            return "[" .. tostring(val) .. "]"
        end
    end
    wrapVal = function(val, level)
        if type(val) == "table" then
            return dumpObj(val, level)
        elseif type(val) == "number" then
            return val
        elseif type(val) == "string" then
            return quoteStr(val)
        else
            return tostring(val)
        end
    end
    dumpObj = function(obj, level)
        if type(obj) ~= "table" then
            return wrapVal(obj)
        end
        level = level + 1
        local tokens = {}
        tokens[#tokens + 1] = "{"
        for k, v in pairs(obj) do
            tokens[#tokens + 1] = getIndent(level) .. wrapKey(k) .. " = " .. wrapVal(v, level) .. ","
        end
        tokens[#tokens + 1] = getIndent(level - 1) .. "}"
        return table.concat(tokens, "\n")
    end
    return dumpObj(obj, 0)
end

local command = {}
function command.GET(key)
	return db[key]
end

--获取整张表 
function command.GETONETABLE(tableName)

	skynet.error("---------GETONETABLE---------");
	local sqlEx = string.format("SELECT * FROM %s", tableName);
	local res = sqldb:query(sqlEx)
	-- print(dump(res))
	return res;
	
end

function command.SET(key, value)
	local last = db[key]
	db[key] = value
	return last
end




function command.REGISTERED(name, password)
	print("db.name",name)
	print("db.password",password)

	--插入数据
	-- local sqlEx = "insert into account (name, password) ".. "values (\'Bdossb\', \'sssss\')";
	
	--删除数据
	-- local sqlEx = "delete from account where name='abc'";
	
	--更新数据
	-- local sqlEx = "UPDATE account SET lv = '1011',password = '2222222'  WHERE name = 'sdsa'";
	
	--查询数据
	local sqlEx = string.format("SELECT * FROM account WHERE NAME='%s'", name);
	-- local sqlEx = "select * from catss where name='Bob'	
	
	local res = sqldb:query(sqlEx)
	print(dump(res))
	return "success"
end


skynet.start(function()
	--
	sqldb = mysql.connect{
		host="localhost",
		port=3306,
		database="skynet",
		user="root",
		password="chenlijie",
		max_packet_size = 1024 * 1024
	}
	if not sqldb then
		skynet.error("*******************************")
		skynet.error("*********SQL Connet Fail*******")
		skynet.error("*******************************")
		skynet.exit();
	end
	
	skynet.dispatch("lua", function(session, address, cmd, ...)
		local f = command[string.upper(cmd)]
		if f then
			skynet.ret(skynet.pack(f(...)))
		else
			error(string.format("Unknown command %s", tostring(cmd)))
		end
	end)
	skynet.register "MYSQLITEDB";
	
	--db:disconnect()
	-- skynet.exit()
end)

