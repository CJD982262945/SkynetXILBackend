--- lobby 服务
-- 管理客户端gate转发的socket消息,管理逻辑服与agent
-- @module lobby
local skynet  = require "skynet"
require "skynet.manager"

local crypt        = require 'crypt'
local cluster      = require "cluster"
local socketdriver = require 'socketdriver'
local netpack      = require "netpack"

local b64encode = crypt.base64encode
local b64decode = crypt.base64decode



local info = {
    gate       = false, -- 网关服务
    login      = false, -- 认证服务
    lobbyName  = false,
}
local NORET = {}

-- 在线用户
-- 通过gate的认证后添加, 连接断开或登出后删除
local user_login = {} -- openID => userinfo
local fd_login = {}  -- fd => addr
local lobby_self



local CMD = {}
local world = {}

local fightnode
local fight_service


function CMD.register_fight(nodeName, address)
    fightnode = nodeName
    fight_service = address

    pcall(skynet.call, world.address, "lua", "attach_fightnode", fightnode, fight_service)

    INFO("---register_fight---nodeName-", nodeName, "-fight_service-", fight_service)
end

--- 启动大厅 向登录服务 注册登陆点；启动逻辑服
-- @within CMD
local next_time = 0
local last_time = os.time()
local function online_count_check()
    skynet.timeout(30 * 100, online_count_check)

    local tnow = os.time()
    local hour = os.date("%H", tnow)
    local minute = os.date("%M", tnow)
    local diffTime = (5 - minute % 5) *60     -- 当前时间距离下一个整5分的差

    last_time = tnow
    if tnow > next_time then
        next_time = tnow + diffTime
        local serial = hour * 12 + minute / 5
        local online = {}
        for _,v in pairs(user_login) do
            if not online[v.worldID] then
                online[v.worldID] = {}
            end

            if not online[v.worldID][v.pf] then
                online[v.worldID][v.pf] = {0,0}
            end

            online[v.worldID][v.pf][1] = online[v.worldID][v.pf][1] + 1
            if v.fd then
                online[v.worldID][v.pf][2] = online[v.worldID][v.pf][2] + 1
            end
        end

        for wd,v in pairs(online) do
            for pf,pv in pairs (v) do
                LOG_ONLINE({
                    world = wd,
                    pf = pf,
                    serial = serial,
                    pv2 = pv[2],
                    pv1 = pv[1],
                })
            end
        end
    end
end

function CMD.startLobby(conf)
    info.gate  = conf.gate
    info.lobbyName = conf.lobbyName
    info.lobbyId = conf.lobbyId

    local lobby = skynet.self()
    assert(info.lobbyName)

    world.address = skynet.queryservice("world")
    world.services = skynet.call(world.address, 'lua', 'getAllServices')

    INFO("-----startLobby.lobbyName----", info.lobbyName .. "node")

    local ok, ret = xpcall(cluster.call, debug.traceback, "loginnode",
        ".login_aux", "register_lobby",  info.lobbyName, skynet.self())
    if not ok then
        ERROR(ret)
    end

    local ok, ret = xpcall(cluster.call, debug.traceback, "fightnode",
        ".fightservice", "register_lobby",  info.lobbyName, skynet.self())
    if not ok then
        ERROR(ret)
    end

    local ok, ret = xpcall(cluster.call, debug.traceback, "loggernode",
        ".remote_logger", "register_lobby",  info.lobbyName, skynet.self())
    if not ok then
        ERROR(ret)
    end

    -- online_count_check()
end

function CMD.stopLobby()
    skynet.call(info.gate, "lua", "close")
end

local subid = 0

function CMD.login(openID, secret, faceID, worldID, pf)
    subid = subid + 1

    local user = user_login[openID]
    if not user then
        user = {
            openID = openID,
            agents = {},
        }
        user_login[openID] = user
    else
        if user.faceID ~= faceID and user.agents[user.faceID] then
            skynet.call(user.agents[user.faceID], "lua", "kick")
        end
    end

    user.pf        = pf                -- 平台id
    user.world     = world.address
    user.services  = world.services
    user.faceID    = faceID
    user.worldID   = worldID
    user.subid     = subid
    user.preSecret = secret
    user.secret    = secret
    user.conn_idx  = 0 -- 与gate断开重连后客户端会增加此索引
    user.fd        = nil

    return subid -- subid 在一个游戏服务器内应该唯一
end

--- call by agent, agent登出后给大厅上报，大厅再上报给login 已成功登出
-- @within CMD
function CMD.logout(openID, faceID, fd)
    local user = user_login[openID]
    if user and user.agents[faceID] then
        user.agents[faceID] = nil
        assert(not next(user.agents))
        user_login[openID] = nil
    end
end

-- 根据 openID 获取用户的 agent
function CMD.get_agent(openID)
    for _, v in pairs(user_login) do
        if v.openID == openID then
            return v.agents[v.faceID]
        end
    end
    return nil
end

-- 根据worldid获取所有用户的agent
-- id 0代表获取所有的
-- id 非0代表指定服
function CMD.get_agents(id)
    local agent = {}
    if id ~= 0 then
        for _, v in pairs(user_login) do
            if v.faceID == id then
                table.insert(agent, v.agents[v.faceID])
            end
        end
    else
        for _, v in pairs(user_login) do
            table.insert(agent, v.agents[v.faceID])
        end
    end
    return agent
end


local function onFD_success_handler(fd, openID, index, faceID)
    local fd_addr = fd_login[fd]
    fd_login[fd]   = nil

    local user = user_login[openID]
    if not user then
        socketdriver.send(fd, netpack.pack("405 Time Out"))
        return false, "405 Time Out"
    end

    if faceID ~= user.faceID and user.agents[user.faceID] then
        skynet.call(user.agents[user.faceID], "lua", "kick")
    end

    local agent
    local beEnter = false
    if not user.agents[faceID] then
        agent = skynet.newservice("agent")
        skynet.send(agent, "lua", "start")
        user.agents[faceID] = agent
    else
        beEnter = true
        agent = user.agents[faceID]
    end
    user.conn_idx = index
    user.faceID = faceID
    user.fd = fd
    user.ip = fd_addr

    skynet.call(agent, "lua", "login", fd, info.gate, lobby_self, info.lobbyName, user, beEnter)
    socketdriver.send(fd, netpack.pack("200 OK"))
    return true
end

local function onFD_failed_handle(fd, openID, err)
    fd_login[fd] = nil

    local user = user_login[openID]
    if user then
        if not next(user.agents) then
            user_login[openID] = nil
        end
    end

end

local function onFD_auth_handler(openId_server_subid, openID, index, hmac)
    local u = user_login[openID]
    if u == nil then
        return "404 User Not Found"
    end
    hmac = b64decode(hmac)
    if index <= u.conn_idx then
        return "403 Index Expired"
    end

    local text = string.format("%s:%s", openId_server_subid, index)
    local v = crypt.hmac_hash(u.secret, text)
    if v ~= hmac then
        return "401 Unauthorized"
    end
end

local function onFD_open_handler(fd, addr)
    fd_login[fd] = addr
end

local function onFD_del_handler(fd)
    fd_login[fd] = nil
end

local SOCKET = require 'lobby.socket' {
    info            = info,
    success_handler = onFD_success_handler,
    failed_handler  = onFD_failed_handle,
    auth_handler    = onFD_auth_handler,
    fdopen_handler  = onFD_open_handler,
    fddel_handler   = onFD_del_handler,
}



skynet.start(function()
    lobby_self = skynet.self()
    
    skynet.dispatch("lua", function(session, source, cmd, subcmd, ...)
        if cmd == "socket" then
            return SOCKET[subcmd](...) -- socket api don't need return
        else
            if dev_lobby_log then
                DEBUG('lobby recv command: ', cmd, table.unpack(...) )
            end
            
            local f = CMD[cmd]
            local ok, ret = xpcall(f, debug.traceback, subcmd, ...)

            if not ok then
                ERROR(string.format("Handle message(%s) failed: %s", cmd, ret))
                return skynet.ret()
            elseif ret ~= NORET then
                return skynet.retpack(ret)
            end
        end
    end)
end)
