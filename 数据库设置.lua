--用户数据设计
---------------------------------------------
-- 1:登陆模块数据设计
--[[
用哈希表来设置账号
Redis 实体关联Key为 Account:UserID
UserID = dbRedis:incr("AccountEntityID")

Lua表模型
Account:UserID = {
	UserBase 		= {},
	UserLoginTime 	= {},
	UserOfflineTime = {},
	....
}

搜索数据方式: 更具用户实体ID来索引数据

哈希表域_1: UserBase
账号数据: 1:UserID(实体ID),  2:UserName(用户名), 3:PassWord(用户密码)
		  4:Level(等级),     5:Exp(经验),	    6:VipLevel(Vip等级)
		  7:Coin(游戏币),    8:Power(体力),	    9:Diamond(钻石)

哈希表域_2: UserLoginTime
用户上线时间: 时间戳

哈希表域_3: UserOfflineTime
用户下线时间: 时间戳

-- 哈希表域_....
--]]
--*******************************************


--用户物品背包设计
---------------------------------------------
-- 2:用户物品背包设计(装备,道具......)
--[[
用哈希表来设计背包
Redis 实体关联Key为 ItemBackPack:UserID

Lua表模型 1
ItemBackPack:UserID = {
	ItemEntityID_1	= {Item表结构},
	ItemEntityID_2	= {Item表结构},
	ItemEntityID_3	= {Item表结构},
	....
}

Lua表模型 1
ItemBackPack:UserID = {
	ItemEntityID_1	= {Item表结构},
	ItemEntityID_2	= {Item表结构},
	ItemEntityID_3	= {Item表结构},
	....
}

Item表结构 = {
	...
}

搜索背包方式: 	  跟具用户实体ID来索引数据
搜索背包物品方式: 跟具用户物品实体ID来索引数据
--]]
--*******************************************

---------------------------------------------
-- 3:

---------------------------------------------
-- 4:

---------------------------------------------
-- 5:

---------------------------------------------
-- 6:

---------------------------------------------
-- 7:

---------------------------------------------
-- 8:
