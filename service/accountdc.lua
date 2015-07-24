local skynet = require "skynet"
local snax = require "snax"
local redis = require "redis"
local config = require "config"

local db

function make_pairs_table(t, fields)
	assert(type(t) == "table", "make_pairs_table t is not table")

	local data = {}

	if not fields then
		for i=1, #t, 2 do
			data[t[i]] = t[i+1]
		end
	else
		for i=1, #t do
			data[fields[i]] = t[i]
		end
	end

	return data
end

function init(...)
    local accountdc_file = skynet.getenv('accountdc')
    local cfg = config(accountdc_file)
    local accountdc_cfg = cfg['redis']

    db = assert(redis.connect{
	    host = accountdc_cfg.host,
	    port = accountdc_cfg.port,
	    db = 0,
	    auth = accountdc_cfg.auth,
    },'accountdc redis connect error')
end

function exit(...)

end

function response.get_nextid()
	return db:incr('nextid')
end

function response.add(row)
    local data = {}
	for k, v in pairs(row) do
		table.insert(data, k)
		table.insert(data, v)
	end

    local key = row.sdkid..':'..row.pid
	local result = db:hmset(key, table.unpack(data))
    if result ~= 'OK' then
        return false
    end

    return true
end

function response.get(sdkid, pid)
    local key = sdkid..':'..pid
 
    local result = db:hgetall(key)
    result = make_pairs_table(result)

	return result
end

