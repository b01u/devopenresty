local get_request, write_log
get_request = function()
  local method = ngx.var.request_method
  local request = ngx.req.raw_header()
  if "POST" == method then
    ngx.req.read_body()
    request = request .. ngx.req.get_body_data()
  end
  return request
end
write_log = function()
  local fp = io.open(ngx.var.PROXY_LOG, "aw")
  local request = get_request()
  fp:write(request .. "\n")
  return fp:close()
end
local mysql = require("resty.mysql")
local db, err = mysql:new()
if not db then
  ngx.say("failed to instantiate mysql: ", err)
  return 
end
db:set_timeout(1000)
local ok, errno, sqlstate
ok, err, errno, sqlstate = db:connect({
  host = '127.0.0.1',
  port = 3306,
  database = "proxy",
  user = "root",
  password = "123456",
  max_packet_size = 1024 * 1024
})
if not ok then
  ngx.say("failed to connect: ", err, ": ", errno, " ", sqlstate)
  return 
end
local res
res, err, errno, sqlstate = db:query("select * from white_list", 10)
if not res then
  ngx.say("bad result: ", err, ": ", errno, ": ", sqlstate, ".")
  return 
end
for _index_0 = 1, #res do
  local i = res[_index_0]
  ngx.log(ngx.ERR, ngx.var.http_host)
  if string.find(ngx.var.http_host, i.host) then
    write_log()
    return 
  end
end
