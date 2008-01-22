TEXFILES = manual.tex overview.tex staff.tex bom.tex boa.tex admin.tex venue.tex trouble.tex
OTHERFILES = 

LATEX = /sw/bin/latex
BIBTEX = /sw/bin/bibtex
PDFLATEX = /sw/bin/pdflatex
DVIPDF = /sw/bin/dvipdf
LATEX2HTML = /sw/bin/latex2html

SCP = scp
SCPOPTS =
SCPHOST = audienc@audience1st.com
SCPPATH = public_html/manual

all: manual.pdf html TAGS

docinstall: all
	$(SCP) $(SCPOPTS) manual/manual.html $(SCPHOST):$(SCPPATH)/manual.html
	$(SCP) $(SCPOPTS) manual.pdf $(SCPHOST):$(SCPPATH)/manual.pdf

html: manual/manual.html

manual/manual.html: $(TEXFILES) $(OTHERFILES)
	-$(LATEX2HTML) -split 2 $<

# manual.pdf: manual.dvi
# 	$(DVIPDF) $<

# manual.dvi: $(TEXFILES)
# 	$(LATEX) manual
# 	$(LATEX) manual

manual.pdf: $(TEXFILES)
	$(PDFLATEX) manual
	$(PDFLATEX) manual

TAGS:
	etags *.tex 

clean:
	/bin/rm -f *.aux *.log *~ *.bbl *.dvi *.pdf *.toc
