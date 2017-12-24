# Paste2

Another pastebin service written in lua and using persistent storage by redis


## Software dependencies
Compile and install nginx with LuaJit, Redis 3, lua-cjson, lua-redis, lua-template

The bare minimum for using highlight.js on a web page is linking to the
library along with one of the styles and calling

## Configuration

You need to create symlinks lua modules in the nginx/lua-active folder.
```bash
ln -s /path/to/lua-resty-template/lib/resty/template.lua /etc/nginx/lua-active/template.lua
ln -s /path/to/lua-redis/redis.lua /etc/nginx/lua-active/redis.lua
```
Adding nginx configuration directive in ```http {}``` section:
```nginx
lua_package_path "/etc/nginx/lua-active/?.lua;;";
lua_shared_dict redisPastePool 64k;
```
To start the instance, you must first start the redis and create a nginx ``` server {}``` section.
Example nginx configuration is located at ``` conf/server.conf ```


Lua paste settings by default
```lua
paste.settings.messagesFadeTimeInOut = 500
paste.settings.messagesViewTimeout = 2000
paste.settings.limitPastesByIPaddr = 100
paste.settings.minMessageLength = 5
paste.settings.minRedisMessageLength = 14
paste.settings.maxMessageLength = 1600000
paste.settings.defaults.expire = 604800 -- 7 days
paste.settings.debug = true -- 7 days

```

## License

Paste2 is released under the GNU 3 License. See [LICENSE][1] file
for details.

[1]: https://raw.githubusercontent.com/PavelPronskiy/paste2/master/docs/LICENSE
