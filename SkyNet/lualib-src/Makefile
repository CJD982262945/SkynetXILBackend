CFLAGS = -fPIC -O3 -Wall -std=c99 -pedantic
CFLAGS += -I../skynet/3rd/lua
LFLAGS = -shared -llua -L../skynet/3rd/lua/

LUA_CLIB_PATH ?= ../luaclib

HASH_SO      			= $(LUA_CLIB_PATH)/hash.so
LFS_SO 		 			= $(LUA_CLIB_PATH)/lfs.so
WEBCLIENT_SO 			= $(LUA_CLIB_PATH)/webclient.so
UTF8_SO 	 			= $(LUA_CLIB_PATH)/utf8.so
CRAB_SO 	 			= $(LUA_CLIB_PATH)/crab.so
WEBSOCKETNETPACK_SO		= $(LUA_CLIB_PATH)/websocketnetpack.so
CLIENTWEBSOCKET_SO		= $(LUA_CLIB_PATH)/clientwebsocket.so 
CJSON_SO				= $(LUA_CLIB_PATH)/cjson.so

SOCKET_PACKAGE_SRC = service_package.c
SOCKET_PACKAGE_SO = $(LUA_CLIB_PATH)/package.so


all: $(HASH_SO) $(LFS_SO) $(WEBCLIENT_SO) $(UTF8_SO) $(CRAB_SO) \
	$(WEBSOCKETNETPACK_SO) $(CLIENTWEBSOCKET_SO) $(CJSON_SO) $(SOCKET_PACKAGE_SO) \
	

$(HASH_SO): lua-hash.c
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $<

$(LFS_SO) :luafilesystem/src/lfs.c 
	gcc -O2 -Wall $^ -fPIC --shared -o $@ -Iluafilesystem/src -I../skynet/3rd/lua


$(WEBCLIENT_SO):lua-webclient.c
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -lcurl -I../3rd/curl/src -I../3rd/curl/include

$(UTF8_SO): crab/lua-utf8.c $<
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -Icrab/

$(CRAB_SO): crab/lua-crab.c $<
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -Icrab/


$(CLIENTWEBSOCKET_SO):lua-clientwebsocket.c
		$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -lpthread

$(WEBSOCKETNETPACK_SO):lua-websocketnetpack.c
		$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -I../skynet/skynet-src

$(CJSON_SO) : | $(LUA_CLIB_PATH)
	cd ./lua-cjson && $(MAKE) -j8  LUA_INCLUDE_DIR=../../skynet/3rd/lua && cp cjson.so ../../luaclib/

$(SOCKET_PACKAGE_SO): $(SOCKET_PACKAGE_SRC)
	$(CC) $(LFLAGS) -o $@ $(CFLAGS) $< -I../skynet/skynet-src

clean:
	rm -f $(LUA_CLIB_PATH)/*.so


.PHONY: all clean
