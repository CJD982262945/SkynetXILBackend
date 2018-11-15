PLAT ?= linux

all : libcurl

libcurl:
	@cd ./curl && ./buildconf && ./configure && $(MAKE) && sudo make install

.PHONY: all
