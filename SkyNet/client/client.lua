#!/usr/bin/env lua53
assert(_VERSION == "Lua 5.3")

package.path  = "client/?.lua;common/?.lua;lualib/?.lua;skynet/lualib/?.lua;"
package.cpath = "skynet/luaclib/?.so;luaclib/?.so"


local socket_type = "tcp"--"ws"
local pf = 1010

local assert = assert
local string = string
local table = table

-- local login_socket = require "socket_tcp" --登录服socket类型
-- local socket  = require ("socket_" .. socket_type) --游戏服socket类型
local socket  = require ("socket_tcp")
local crypt   = require "client.crypt"
local settings = require 'settings'
local md5 = require "md5"

local protobuf = require 'protobuf'
local pb_decode = protobuf.decode
local pb_encode = protobuf.encode
protobuf.register(io.open("proto/game.pb", "rb"):read('a'))

local inspect_lib = require "inspect"
function inspect(value)
    return inspect_lib(value, {
    process = function(item, path)
        if type(item) == "function" then
            return nil
        end
        
        if path[#path] == inspect_lib.METATABLE then
            return nil
        end
        
        return item
    end,
    newline = " ",
    indent = ""
})
end


local function clear_metatable (tb)
  setmetatable(tb, nil)
  for k, v in pairs(tb) do
    if type(v) == 'table' then
      clear_metatable(v)
    end
  end
end

local rpc_info = require 'rpc_info'
local req_t    = rpc_info.req_dict
local res_t    = rpc_info.res_dict
local MI       = rpc_info.rpc_dict
local MN       = {}

for k, v in pairs(MI) do
  MN[v] = k
end

local termfx = require "termfx"
local ui = require 'simpleui'

local output = {}
local function p(...)
  local l = {}
  for _, v in ipairs {...} do
    table.insert(l, tostring(v))
  end
  table.insert(output, table.concat(l, '\t'))
end

local function block_read_pack(sock)
  local len = sock:receive(2)
  if len then
    len = len:byte(1) * 256 + len:byte(2)
    local msg, err, parts = sock:receive(len)
    if msg and #msg == len then
      return msg
    else
      sock:close()
      return nil, err
    end
  end
end

local function mk_recv(sock, secret)
  return function()
    sock:settimeout(0)
    local len, r = sock:receive(2)
    if len then
      len = len:byte(1) * 256 + len:byte(2)
      sock:settimeout(nil) -- or 1 seconds
      local msg, err = sock:receive(len)
      if msg then
        assert(#msg == len)

        local buf = crypt.desdecode(secret, msg)
        local msgid = string.unpack('>I4', buf)
        local res_msg = pb_decode(res_t[msgid], buf:sub(5))
        protobuf.extract(res_msg)
        clear_metatable(res_msg)
        return true, msgid, res_msg

      else
        return false, err
      end
    else
      if r == 'timeout' then
        return nil
      elseif r == 'closed' then
        return false, 'socket close'
      end
    end
  end
end

local function mk_send(sock, secret)
  return function (msgid, msg)
    inspect(msg)
    local pb_buf = protobuf.encode(req_t[msgid], msg)
    local buf = string.pack('>I4c' .. #pb_buf, msgid, pb_buf)
    sock:settimeout(0.5)
    sock:send(string.pack('>s2', crypt.desencode(secret, buf)))
  end
end


local function main(ip, port, uid, worldId, subid, secret)
  termfx.init()
  termfx.inputmode(termfx.input.ALT + termfx.input.MOUSE)
  termfx.outputmode(termfx.output.COL256)

  local sock = socket.connect(ip, port)

  local handshake = string.format("%s@%s#%s:%d",
    crypt.base64encode(uid),
    crypt.base64encode(worldId),
    crypt.base64encode(subid), 1) -- 1 重连+1

  local hmac = crypt.hmac64(crypt.hashkey(handshake), secret)

  local hs = handshake .. ':' ..  (crypt.base64encode(hmac))
  sock:send(string.pack(">s2", hs))

  local res = block_read_pack(sock)
  if not res then
    return p 'connect gate error'
  end

  local recv_msg = mk_recv(sock, secret)
  local send_msg = mk_send(sock, secret)

  local function excutefile(ch)
      local file = io.open("./client/exc.lua")

      local s = file:read("a")
      file:close()
      local env = _ENV
      env.send_msg = send_msg
      env.MI = MI
      env.CH = ch
      local f = load(s, "exc", "t", env)
      assert(f, inspect(env.CH))
      f()
  end

  local ok, err = pcall(function()

    local msg_list = {}

    local quit = false
    while true do
      termfx.clear(termfx.color.WHITE, termfx.color.BLACK)

      local w, h = termfx.size()

      do
        local msg_width = 128
        ui.box(2, 2, msg_width, h - 2)

        local idx = # msg_list
        for i = h - 1, 2, -2 do
          local m = msg_list[idx]
          if m then
            termfx.printat(2, i, m[1] .. '\n' .. m[2], msg_width)
          else
            break
          end

          idx = idx - 1
        end
      end

      termfx.present()

      local evt = termfx.pollevent(100)

      if evt then
        local cmd = ""
        if evt.type == 'key' then
          local ch = evt.char:lower()

          -- TODO: 1 支持输入字符串？ 2 映射表
          if ch == 'q' then
            if ui.ask('really want to quit?') then break end
          elseif ch == 'e' then
            send_msg(MI.enterGameWorld, { worldID = 1 })
          elseif ch == 'c' then
              local namei = "test" .. math.random(1, 100000)
            send_msg(MI.createPlayer, { name = namei, avatar = 1})
          else
              excutefile(ch)
          end
        elseif evt.type == 'mouse' then
        elseif evt.type == 'resize' then
        end

      else
        local r, msgid, msg = recv_msg()
        if r == true then
          table.insert(msg_list, {
            MN[msgid] or msgid,
            inspect(msg)
          })
        elseif r == false then
          p('=======网络断开，结束客户端=====', msgid)
          break
        end
      end
    end
  end)

  termfx.shutdown()
  if not ok then
    print("Error: ", err)
  end
end

local function auth()
  local sock = socket.connect('127.0.0.1', settings.login_conf.login_port)

  local challenge = crypt.base64decode(sock:receive('*l'))
  local clientkey = crypt.randomkey()
  sock:send(crypt.base64encode(crypt.dhexchange(clientkey)) .. '\n')

  local line = crypt.base64decode(sock:receive '*l' )
  local secret = crypt.dhsecret(line, clientkey)

  local hmac = crypt.hmac64(challenge, secret)
  -- 5. 回应服务器的握手挑战码，确认握手正常
  sock:send(crypt.base64encode(hmac) .. '\n')

  local token
  if arg[1] ~= "true" then
    token = {
      openId   = "client_test_1",
      loginSdk = 1,
      worldId  = 1,
      pf       = pf,
      userdata = "",
    }
  else
    local uin = arg[2] or "100010000000001"
    local worldId = tonumber(string.match(uin, "%d+(%d%d%d%d)%d%d%d%d%d%d%d%d%d%d"))
    token = {
      openId   = uin,
      loginSdk = 3,
      worldId  = worldId,
      pf       = pf,
      userdata = md5.sumhexa(uin .. "NGE8sVGVy3rvY4e6334%!$GflP3vdbCdo830qHxVa"),
    }
  end

  local function encode_token(token)
    return string.format("%s@%s:%s:%s:%s",
      crypt.base64encode(token.openId),
      crypt.base64encode(token.loginSdk),
      crypt.base64encode(token.worldId),
      crypt.base64encode(token.pf),
      crypt.base64encode(token.userdata))
  end

  -- 6. DES加密发送 token串
  local etoken = crypt.desencode(secret, encode_token(token))
  sock:send(crypt.base64encode(etoken) .. '\n')

  -- 服务器解密后调用定制的auth和login handler处理客户端请求

  -- 7. 从服务器读取 登录结果： 状态码 和 subid
  local result = sock:receive '*l'
  local code = tonumber(string.sub(result, 1, 3))
  assert(code == 200)
  sock:close()

  local subid = crypt.base64decode(string.sub(result, 5))
  local ip, port, uid, subid = subid:match("([^:]+):([^:]+)@([^@]+)@(.+)")

  return ip, port, uid, token.worldId, subid, secret
end

local ip, port, uid, worldId, subid, secret = auth()
p(ip, port, uid, worldId)
main(ip, port, uid, worldId, subid, secret)
