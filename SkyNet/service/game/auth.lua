local skynet = require "skynet"
local service = require "service.service"
local client = require "service.client"

local auth = {}
local users = {}
local cli = client.handler()

function cli:ping()
	DEBUG("ping")
end

function auth.shakehand(fd)
	local c = client.dispatch { fd = fd }
	return c.userid
end

service.init {
	command = auth,
	info = users,
	init = client.init "proto",
}
