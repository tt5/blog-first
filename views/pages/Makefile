MD := $(wildcard *.m4d)
HTML    := $(MD:.m4d=.md.html)

.PHONY: all

all: $(HTML)

$(HTML): %.md.html: %.m4d
	awk -f m4ify.awk $^ | m4 -R def.m4d > $*.md
	lua ../../src/md2html.lua $*.md
	node ../../html2katex.js $@ > $*.html
#  @touch $@
