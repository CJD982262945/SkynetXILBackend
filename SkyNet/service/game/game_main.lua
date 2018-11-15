local skynet = require 'skynet'
require "skynet.manager"
local cluster      = require "cluster"


skynet.start(function ()
  -- 基础服务
  local settings = require 'settings'
  local lobbyId = skynet.getenv("lobbyId")
  INFO("-----lobbyId-----", lobbyId, " will begin")
  local cfg = settings.lobbys[lobbyId]
  assert(cfg)

  skynet.uniqueservice('debug_console', cfg.console_port)
  skynet.uniqueservice('word_crab', cfg.word_crab_file)
  skynet.uniqueservice('dbproxy', cfg.nodeName)
  skynet.uniqueservice("game_shutdown")
  

  INFO("-----lobbyId-----", lobbyId, " start OK")
  skynet.exit()
end)

