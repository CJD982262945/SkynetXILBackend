local dbproxyx = require 'dbproxyx'
local account_db_key = require "dbset".account_db_key

local game_server_conf = require "game_server_conf"
local login_const = require "login_api.login_const"


local M = {}


function gen_real_openid(openId, sdk, pf)
    return string.format("%d_%d_%s", pf, sdk, openId)
end

function M.get_real_openid(openId, sdk, pf)
    if sdk == login_const.sdk.debug then
        -- TODO: 写相关操作日志
    end

    local uin = gen_real_openid(openId, sdk, pf)
    local data = dbproxyx.get(account_db_key.tbname, account_db_key.cname, uin)
    if not data then
        data = {
            uin = uin,
            data = {
                openId = openId,
                sdk = sdk,
                pf = pf,
            }
        }

        dbproxyx.set(account_db_key.tbname, account_db_key.cname, uin, data)
    end
    return uin
end

function M.get_server(serverId)
    local lobbyInfo = game_server_conf.lobbys[serverId]
    assert(lobbyInfo, "GameServer not found ID=" .. serverId)
    return lobbyInfo.nodeName .. "node"
end

local user_online = {}	-- 记录玩家所登录的服务器


function M.get_user_online(uid)
    return user_online[uid]
end

function M.del_user_online(uid)
    user_online[uid] = nil
end

function M.add_user_online(uid, user)
    user_online[uid] = user
end

return M