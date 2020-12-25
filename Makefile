FILES = $(shell find app public lib features spec config db -type f -a '!' -name '\#*' -a '!' -name '.\#' -a '!' -name '*.min.js' -a '!' -name rails.js)

all: TAGS

TAGS: $(FILES)
	@etags $(FILES) >/dev/null
