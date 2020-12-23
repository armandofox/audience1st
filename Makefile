FILES = index faq payment privacy
HTMLFILES = $(addsuffix .html,$(FILES))
HAMLFILES = $(addsuffix .haml,$(HTMLFILES))
OTHERFILES = header.html footer.html faq-nav.html
HAML = haml

all: $(HTMLFILES) $(OTHERFILES)

%.html: %.html.haml $(OTHERFILES)
	$(HAML) $< $@

clean:
	/bin/rm $(HTMLFILES)
