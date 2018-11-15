local skynet = require "skynet"
local socket = require "skynet.socket"
local proxy = require "service.socket_proxy"
local service = require "service.service"

local hub = {}
local data = { socket = {} }

local function auth_socket(fd)
	return (skynet.call(service.auth, "lua", "shakehand" , fd))
end

local function assign_agent(fd, userid)
	skynet.call(service.manager, "lua", "assign", fd, userid)
end

function new_socket(fd, addr)
	data.socket[fd] = "[AUTH]"
	proxy.subscribe(fd)
	local ok , userid =  pcall(auth_socket, fd)
	if ok then
		data.socket[fd] = userid
		if pcall(assign_agent, fd, userid) then
			return	-- succ
		else
			ERROR("Assign failed %s to %s", addr, userid)
		end
	else
		ERROR("Auth faild:", addr)
	end
	proxy.close(fd)
	data.socket[fd] = nil
end

function hub.kick()
end

function hub.open(ip, port)
	INFO(string.format("Listen %s:%d", ip, port))
	assert(data.fd == nil, "Already open")
	data.fd = socket.listen(ip, port)
	data.ip = ip
	data.port = port
	socket.start(data.fd, new_socket)
end

function hub.close()
	assert(data.fd)
	INFO(string.format("Close %s:%d", data.ip, data.port))
	socket.close(data.fd)
	data.ip = nil
	data.port = nil
end

service.init {
	command = hub,
	info = data,
	require = {
		"auth",
		"manager",
	}
}
