
FILES = $(shell find app lib features spec config -name '*.rb' -or -name '*.rhtml'  -or -name '*.haml' -or -name '*.html.erb' -or -name '*.haml.erb' -or -name '*.html.haml' -or -name '*.js' -or -name '*.rake' -or -name '*.yml' -or -name '*.feature')
PLUGINS = $(shell find vendor/plugins -name '*.rb' -print -or -name '*.yml')

all:
	@echo Must force explicit target: dev, TAGS, doc

dev: TAGS
	-cd config && ln -s database.yml.dev database.yml
	-cd config && ln -s facebooker.yml.dev facebooker.yml
	mkdir log
	touch log/development.log
	-rake db:migrate
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
