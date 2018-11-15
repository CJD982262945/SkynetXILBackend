PLAT ?= linux

.PHONY: all 

all : third_part deps skynet busilogger rpc


termfxso=luaclib/termfx.so

clientdebug: CLIENT_DEBUG := true

clientdebug: | client

client: $(termfxso)

	@if [ ! -f "client/client.lua" ]; then cp client/client_template.lua client/client.lua; fi
	./client/client.lua $(CLIENT_DEBUG) $(UIN)


third_part:
	@cd ./3rd && $(MAKE)


$(termfxso) :
	@cd client/termfx && make
	cp -f client/termfx/termfx.so luaclib/


skynet: third_part deps
	cd skynet && make linux

deps: third_part
	@cd lualib-src && $(MAKE)
	
rpc:
	@cd proto && $(MAKE)

test:
	@sudo touch 1.txt
