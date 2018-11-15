--- lobby 服务
-- 管理gate转发的socket消息
-- @module lobby.socket

local skynet  = require "skynet"

local netpack      = require "netpack"
local socketdriver = require 'socketdriver'

local crypt   = require 'crypt'
local b64decode = crypt.base64decode

local dispatch_lobby_msg = require 'lobby.handler'

local assert = assert

return function (data)

local info            = data.info
local success_handler = data.success_handler
local failed_handler  = data.failed_handler
local auth_handler    = data.auth_handler
local fdopen_handler  = data.fdopen_handler
local fddel_handler   = data.fddel_handler

local SOCKET = {}

--- 如果重连次数超出限制，禁止接入
-- @within SOCKET
function SOCKET.open(fd, addr)
    skynet.call(info.gate, "lua", "accept", fd)
    fdopen_handler(fd, addr)
end

-- atomic, no yield
local function do_auth(fd, message)
    local uid_server_subid, index, hmac = string.match(message, "([^:]*):([^:]*):([^:]*)")
    local uid, server, subid = string.match(uid_server_subid, "([^@]*)@([^@]*)#([^#]*)")
    uid = b64decode(uid)
    server = tonumber(b64decode(server))
    subid = tonumber(b64decode(subid))
    index = tonumber(index)
    local err = auth_handler(uid_server_subid, uid, index, hmac)
    if err then
        return err
    end
    return nil, uid, index, server, subid
end

--- 客户端socket 消息，处理认证 获取游戏服列表 公告等工作
-- @within SOCKET
function SOCKET.data(fd, msg)
    local ok, err, uid, index, server, subid  = pcall(do_auth, fd, msg, socket_addr)
    if not ok or err then
        DEBUG('lobby: fd认证失败:', fd, err)
        failed_handler(fd, uid, err)
        socketdriver.send(fd, netpack.pack(err))
        skynet.call(info.gate, 'lua', 'kick', fd)
    else
        local ok, err = success_handler(fd, uid, index, server)
        if ok then
            DEBUG('lobby: fd认证成功:', fd)
        else 
            DEBUG('lobby: fd认证失败:', fd, err)
            fddel_handler(fd)
            skynet.call(info.gate, 'lua', 'kick', fd)
        end
    end
end

--- 客户端断开
-- @within SOCKET
function SOCKET.close(fd)
    DEBUG('lobby: 客户端socket close:', fd)
    --close_connection(fd)
end

--- 客户端出错
-- @within SOCKET
function SOCKET.error(fd, msg)
    DEBUG('lobby: 客户端socket error:', fd, msg)
end

--- 客户端socket warning
-- @within SOCKET
function SOCKET.warning(fd, size)
    DEBUG('lobby: 客户端socket warning:', fd, size)
end

return SOCKET

end
