
FILES = $(shell find app -name '*.rb' -print -or -name '*.rhtml' -print -or -name '*.haml' -print -or -name '*.yml' -print)
PLUGINS = $(shell find vendor/plugins -name '*.rb' -print -or -name '*.yml' -print)

all:
	@echo Must force explicit target

TAGS: $(FILES) $(PLUGINS)
	etags $(FILES) $(PLUGINS)

.PHONY: doc
doc:	
	cd doc && make
