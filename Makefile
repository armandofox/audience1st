
FILES = $(shell find app lib features spec config -name '*.rb' -or -name '*.rhtml'  -or -name '*.haml'  -or -name '*.rake' -or -name '*.yml')
PLUGINS = $(shell find vendor/plugins -name '*.rb' -print -or -name '*.yml')

all:
	@echo Must force explicit target: dev, TAGS, doc

dev:
	-ln -s config/database.yml.dev ../config/database.yml
	mkdir log
	touch log/development.log
	-ln -s ~/Documents/fox/projects/stylesheets/sandbox public/stylesheets/venue

#TAGS: $(FILES) $(PLUGINS)
#	etags $(FILES) $(PLUGINS)

tt:
	echo $(FILES)

TAGS: $(FILES)
	etags $(FILES) >/dev/null

.PHONY: doc
doc:	
	cd manual && make
