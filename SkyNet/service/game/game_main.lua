local skynet = require 'skynet'
require "skynet.manager"
local cluster = require "skynet.cluster"

skynet.start(function ()
  local settings = require 'settings'
  local lobbyId = skynet.getenv("lobbyId")
  INFO("-----GameServer-----", lobbyId, " will begin")
  local cfg = settings.lobbys[lobbyId]
  assert(cfg)

  skynet.uniqueservice('debug_console', cfg.console_port)
  skynet.uniqueservice('word_crab', cfg.word_crab_file)
  skynet.uniqueservice('dbproxy', cfg.nodeName)
  
  local proto = skynet.uniqueservice "protoloader"
	skynet.call(proto, "lua", "load", {
		"proto.c2s",
		"proto.s2c",
  })

  local hub = skynet.uniqueservice "hub"
  skynet.call(hub, "lua", "open", "0.0.0.0", cfg.gate_port)

  cluster.register(cfg.nodeName)
  cluster.open(cfg.nodeName .. "node")

  skynet.uniqueservice("game_shutdown")
  INFO("-----GameServer-----", lobbyId, " start OK")

  skynet.exit()
end)

