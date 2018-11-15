local skynet = require 'skynet'
require "skynet.manager"
local cluster      = require "cluster"


skynet.start(function ()
  -- 基础服务
  local setting_template = require 'settings'
  local lobbyId = tonumber(skynet.getenv("lobbyId")) 
  INFO("-----lobbyId-----", lobbyId, " will begin")

  local settings = setting_template.lobbys[lobbyId]
  assert(settings)

  skynet.uniqueservice('debug_console', settings.console_port)
  skynet.uniqueservice('dbproxy', settings.nodeName)
  skynet.uniqueservice('word_crab', setting_template.word_crab_file)
  skynet.uniqueservice("game_shutdown")
  

  INFO("-----lobbyId-----", lobbyId, " start OK")
  skynet.exit()
end)

