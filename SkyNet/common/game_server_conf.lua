local settings = require 'settings'

local function calLobby(id)
    local lobby = settings.lobbys[id]
    assert(lobby)
    return lobby
end

local function calIPStr(id)
    local lobby = calLobby(id)
    return lobby.gate_host .. ":" .. lobby.gate_port
end


local M = {
    version = "2018_11_15_1",
    lobbys = {
        '1' = { outerIp = calIPStr('1'), name = "lobby1", },
    },
    },
}

return M
