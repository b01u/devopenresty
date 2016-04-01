-- 声明函数， 以防不能调用
local get_request, write_log
-- 获取request数据包
get_request = ->
    method = ngx.var.request_method
    request = ngx.req.raw_header!

    if "POST" == method
        ngx.req.read_body!
        request ..= ngx.req.get_body_data!
    return request

-- request 数据包写入日志
write_log = ->
    fp = io.open ngx.var.PROXY_LOG, "aw"
    request = get_request!
    --fp:write( ngx.var.FLAG.."\n"   )
    fp\write request.."\n"
    fp\close!

-- 调用resty.mysql库
mysql = require "resty.mysql"
db, err = mysql\new!
if not db
    ngx.say "failed to instantiate mysql: ", err
    return
db\set_timeout 1000

ok, err, errno, sqlstate = db\connect host: '127.0.0.1', port:  3306, database: "proxy", user: "root", password: "123456", max_packet_size: 1024 * 1024

if not ok
    ngx.say "failed to connect: ", err, ": ", errno, " ", sqlstate
    return

-- run a select query, expected about 10 rows in
-- the result set:
res, err, errno, sqlstate = db\query "select * from white_list", 10
if not res
    ngx.say "bad result: ", err, ": ", errno, ": ", sqlstate, "."
    return
-- 域名白名单过滤
for i in *res
    ngx.log ngx.ERR, ngx.var.http_host
    if string.find ngx.var.http_host, i.host
        write_log!
        return
