-- Paste logic written by lua
-- Description: paste data logic
-- Version: 0.1.0
-- Author:  Pavel Pronskiy
-- Contact: pavel.pronskiy@gmail.com
-- Copyright (c) 2016-2017 paste Pavel Pronskiy

local cjson = require "cjson"
local redis = require "redis"
local template = require "template"
local red = redis:new()
local paste = {}
paste.ngx = {}
paste.ngx.rp = ngx.shared.redisPastePool
paste.debug = {}
paste.debug.stackTrace = true
paste.redis = {}
paste.construct = {}
paste.exception = {}
paste.protected = {}
paste.settings = {}
paste.settings.messages = {}
paste.settings.defaults = {}
paste.path_assets = 'assets'
paste.titleFormPage = 'Safe wording service'
paste.settings.messages.maxLengthMessage = 'Maximum limit message exceeded'
paste.settings.messages.minLengthMessage = 'Minimum limit message exceeded'
paste.settings.messages.placeholderTextarea = 'Typing message...'
paste.settings.hashUrlLen = 6
paste.settings.messagesFadeTimeInOut = 500
paste.settings.messagesViewTimeout = 2000
paste.settings.limitPastesByIPaddr = 100
paste.settings.minMessageLength = 5
paste.settings.maxMessageLength = 1600000
paste.settings.defaults.expire = 604800 -- 7 days
paste.settings.debug = true -- 7 days
paste.redis.timeout = 1000

paste.redis.mapPool = {
	["127.0.0.3"] = 6379,
	["127.0.0.2"] = 6379,
	["127.0.0.3"] = 6379,
	["127.0.0.4"] = 6379,
	["127.0.0.1"] = 6379,
	["127.0.0.7"] = 6379,
	["127.0.0.8"] = 6379
}

paste.redis.prefix = {
	["redispool"] = "redispool",
	["lastModified"] = ":lastmodified",
	["ETag"] = ":etag",
	["key"] = "paste:store",
	["keyPastes"] = "paste:collects",
	["log"] = "lg",
	["clicks"] = "cs",
	["counter"] = "cr",
	["hosts"] = "hs",
	["rev"] = "r"
}

function paste.ngx.headers(object)

	 local policy = {}
	 local k = {}

	    if object.header == 'json'
	  then ngx.header["Content-Type"] = 'application/json'
	elseif object.header == 'html'
	  then ngx.header["Content-Type"] = 'Content-type: text/html; charset=utf-8'
	elseif object.header == 'text'
	  then ngx.header["Content-Type"] = 'Content-type: text/plain; charset=utf-8'
	   end

	ngx.header["Cache-Control"] = "public"
	ngx.status = ngx.HTTP_OK
end

-- split string 127.0.0.1:1234
function paste.split(sep,str)
   local ret={}
   local n=1
   for w in str:gmatch("([^"..sep.."]*)") do
      ret[n] = ret[n] or w -- only set once (so the blank after a string is ignored)
      if w=="" then
         n = n + 1
      end -- step forwards on a blank but not a string
   end
   return ret
end

-- finally output data
function paste.construct.message(o)
	paste.ngx.headers(o)
	return ngx.print(o.message)
end

-- get keyhash modules
function paste.construct.textPlainMessage(object)

	local o = {}
	local t = {}

	o.hash = paste.redis.prefix.key .. ':' .. object.hash
	t.data, err = red:get(o.hash)

	  if type(t.data) == 'userdata'
	then paste.exception.throw({
			message = 'Message not found',
			code = 1000,
			header = 'json'

		 })
	end

	  if (string.len(t.data) <= 14) -- length 14 is empty data of redis
	then paste.exception.throw({
			code = 112,
			header = 'text'

		 })
	end

	t.header = 'text'
	t.decodeParams = paste.protected.JSONdecode(t.data)
	t.message = ngx.decode_base64(t.decodeParams.textareaBase64)
	return paste.construct.message(t)
end

function paste.construct.htmlForm(o)
	paste.ngx.headers(o)

	return template.render("main.html", {
		title = paste.titleFormPage,
		path_assets = paste.path_assets,
		js_settings = paste.protected.JSONencode(paste.settings)

	})
end

function paste.construct.saveMessage(object)
	local o = {}
	local t = {}

	o.remote_addr = ngx.var.remote_addr
	o.user_agent = ngx.encode_base64(ngx.var.http_user_agent)

	ngx.req.read_body()
	local post, err = ngx.req.get_post_args()
	if not post
	then paste.exception.throw({
			message = 'Internal server error',
			code = 108,
			header = 'json'
		})
	end

	 if post.key ~= nil
	and post.textarea ~= nil
	and string.len(post.textarea) >= paste.settings.minMessageLength
	and string.len(post.textarea) <= paste.settings.maxMessageLength
	then
		o.header = 'json'
		o.textareaBase64 = ngx.encode_base64(post.textarea)
		o.hashURL = string.sub(ngx.encode_base64(ngx.md5(post.textarea)), 0, paste.settings.hashUrlLen)
		t.redisKey = paste.redis.prefix.key .. ':' .. o.hashURL
		t.redisHistKey = paste.redis.prefix.keyPastes .. ':' .. post.key
		o.dateAdded = ngx.http_time(ngx.time())
		t.cjsonConstruct = paste.protected.JSONencode(o)
		t.successMessage = paste.protected.JSONencode({
			status = "success",
			message = "Added success",
			created = o.dateAdded,
			hashURL = o.hashURL
		})

		local res = red:llen(t.redisKey)
		if res == false
		then paste.exception.throw({
				message = 'Message already exist',
				code = 108,
				header = 'json'
			})
		else
			local rset, err = red:set(t.redisKey, t.cjsonConstruct)
			if not rset
			then paste.exception.throw({
					message = 'Internal server error from POST save message ' .. err,
					code = 108,
					header = 'json'
				})
			else
				red:lpush(t.redisHistKey, o.hashURL)

				  if post.expire ~= nil
				 and post.expire == 'true'
				then t.expire = paste.settings.defaults.expire
					 red:expire(t.redisKey, t.expire)
				 end

				-- success method
				paste.ngx.headers(o)
				ngx.print(t.successMessage)
			end

		end
	else paste.exception.throw({
			message = 'Internal server error',
			code = 108,
			header = 'json'
		})
	end
	-- ngx.say(args.textarea)
end

-- json arrays syntax protected
function paste.protected.JSONencode(o)
	local success, resource = pcall(cjson.encode, o)
	if not success
	then paste.exception.throw({
		code = 111
		})
	else return resource
	end
end

function paste.protected.JSONdecode(o)
	local success, resource = pcall(cjson.decode, o)
	if not success
	then paste.exception.throw({
		message = 'json decode error',
		header = 'json',
		code = 110
	})
	else return resource
	end
end

-- get client pastes
function paste.construct.getPastesByFingerprint(o)
	local t = {}
	local histData = {}
	local ret = {}

	t.hash = paste.redis.prefix.keyPastes .. ':' .. o.fingerprint
	t.header = 'json'

	local histLen, errLen = red:llen(t.hash)
	if not histLen
	then paste.exception.throw({
			message = 'Internal error redis: ' .. errLen,
			header = 'html',
			code = 107
		})
	else
		if histLen > 0
		then
			local lRange, errLrange = red:lrange(t.hash, 0, histLen)
			if not lRange
			then paste.exception.throw({
					message = 'Internal error redis: ' .. errLrange,
					header = 'html',
					code = 107
				})
			else
				for i, x in pairs(lRange)
				 do lRange[i] = paste.redis.prefix.key .. ':' .. x
				end

				lMget, errMget = red:mget(unpack(lRange))
				if #lMget > 0
				then for i, x in pairs(lMget)
					 do tx = paste.protected.JSONdecode(x);
					    histData[i] = {}
					    histData[i].url = tx.hashURL
					    histData[i].created = tx.dateAdded
					end

					 ret.type = 'clientHistory'
					 ret.status = 'success'
					 ret.data = histData

				end

				paste.ngx.headers(t)
				return ngx.print(paste.protected.JSONencode(ret))
			end
		else
			paste.ngx.headers(t)
			t.message = paste.protected.JSONencode({
				status = "empty",
				message = "Empty data"
			})

			return ngx.print(t.message)
		end
	end

	-- paste.ngx.headers(t)
	-- return ngx.print(cjson.encode(ret))

end


-- route objects
function paste.router(object)
	  if object.route == 'postClientMessage'
	then paste.construct.saveMessage(object)
	 end

	  if object.route == 'index'
	then paste.construct.htmlForm(object)
	 end

	  if object.route == 'getClientPastedMessages'
	then paste.construct.getPastesByFingerprint(object)
	 end

	  if object.route == 'message'
	then paste.construct.textPlainMessage(object)
	 end
end

-- redis connect
function paste.combine(o)
	local target = false
	local msg = {}
	local rs = {}

	rs.ord = {}
	rs.hp = {}
	rs.lastRedisHost = paste.ngx.rp:get(paste.redis.prefix.redispool)
	red:set_timeout(paste.redis.timeout)
	-- red:set_keepalive(10000, 100)

	 for host, port in pairs(paste.redis.mapPool)
	  do table.insert(rs.ord, host)
	 end

	  if #rs.ord == 0
	then paste.exception.throw({
			code = 116
		 })
	end

	  if rs.lastRedisHost ~= nil
	then rs.lastRedisConnection = paste.split(':', rs.lastRedisHost)
		 rs.hp.host = rs.lastRedisConnection[1]
		 rs.hp.port = rs.lastRedisConnection[2]
		 local status, err = red:connect(rs.hp.host, rs.hp.port)
		   if status
		 then target = true
		 else target = false
		  end
	end

	  if target == false
	then for host, port in pairs(paste.redis.mapPool)
		  do local status, err = red:connect(host, port)
		   		if status
			  then rs.hostOnline = host .. ':' .. port
			       target = true
				   return paste.ngx.rp:set(paste.redis.prefix.redispool, rs.hostOnline)
			   end
		 end
	end

	 if target == true
   then paste.router(o)
   else paste.exception.throw({
			code = 108
		})
	end
	-- return red:close();
end

--[[function paste.combine(o)
	local target = false

	red:set_timeout(paste.redis.timeout)

	 for host, port in pairs(paste.redis.mapPool)
	  do local status, err = red:connect(host, port)
	   	   if status
	      then target = true
			 return paste.router(o)
		  end
	 end

	if target == false
   then paste.exception.throw({
   			message = 'Cannot connect to redis',
   			header = 'json',
			code = 108
		})
	end
	

end
--]]
-- route
function paste.route()

	local o = {}
	o.req = paste.split('/', ngx.var.request_uri)
	-- get paste message
	  if o.req[3] == 'text'
	  or string.len(o.req[2]) == paste.settings.hashUrlLen
	then o.route = 'message'
		 o.hash = o.req[2]
		 return paste.combine(o)
	 end

	-- post paste save
	  if o.req[2] == 'api'
	 and o.req[3] == 'post'
	 and ngx.var.request_method == 'POST'
	then o.route = 'postClientMessage'
		 return paste.combine(o)
	 end

	-- get pastes hist
	  if o.req[2] == 'api'
	 and o.req[3] == 'pastes'
	 and ngx.var.request_method == 'GET'
	 and string.len(o.req[4]) == 32
	then o.route = 'getClientPastedMessages'
		 o.fingerprint = o.req[4]
		 return paste.combine(o)
	 end

	  if ngx.var.request_uri == '/'
	 and ngx.var.request_method == 'GET'
	then o.route = 'index'
		 o.header = 'html'
		 return paste.combine(o)
	 end

	-- not found any
	paste.exception.throw({
		message = 'Not found fail',
		header = 'html',
		code = 107
	})

end

function paste.exception.throw(o)
	exception = {}
	exception.code = o.code
	exception.header = 'json'
	exception.message = o.message
	return error()
end

function paste.exception.message(object)

	local o = {}
	local r = {}
	local t = {}

	  if type(object.status) == 'string'
	then o.status = object.status
	else o.status = 'error'
	 end

	t.date = ngx.http_time(ngx.time())
	t.status = o.status
	t.message = object.message
	t.code = object.code

	if paste.debug.stackTrace == true
   then t.stack = object.stacktrace
    end

 	r = paste.protected.JSONencode(t)

	object.domain = ngx.var.host
	paste.ngx.headers(object)
	ngx.print(r)
	return ngx.exit(ngx.HTTP_OK)
end

-- return exception error
function paste.exception.catch()
	return paste.exception.message(exception)
end

return xpcall(paste.route, paste.exception.catch)
