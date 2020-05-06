FILES = $(shell find app public lib features spec config db '(' -name '*.rb' -or -name '*.rhtml'  -or -name '*.haml' -or -name '*.html.erb' -or -name '*.haml.erb' -or -name '*.html.haml' -or -name '*.js' -or -name '*.rake' -or -name '*.yml' -or -name '*.feature' ')' -a '!' -name '*.min.js' -a '!' -name rails.js)

all: TAGS

TAGS: $(FILES)
	@etags $(FILES) >/dev/null
