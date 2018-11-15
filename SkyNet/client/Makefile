PLAT ?= linux

all : termfx lsocket

termfx:
	@cd ./curl && ./buildconf && ./configure && $(MAKE) && sudo make install

lsocket:
	@cd ./curl && ./buildconf && ./configure && $(MAKE) && sudo make install

.PHONY: all
