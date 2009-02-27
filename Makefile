
FILES = $(shell find . -name '*.rb' -or -name '*.rhtml'  -or -name '*.haml'  -or -name '*.yml' -print)
PLUGINS = $(shell find vendor/plugins -name '*.rb' -print -or -name '*.yml' -print)

all:
	@echo Must force explicit target: dev, TAGS, doc

dev:
	mkdir log
	cp config/database.yml config/database.yml.dev

#TAGS: $(FILES) $(PLUGINS)
#	etags $(FILES) $(PLUGINS)

TAGS: $(FILES)
	etags $(FILES) >/dev/null

.PHONY: doc
doc:	
	cd manual && make
