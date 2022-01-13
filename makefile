MARKDOWN = pandoc -H header.html -c style.css
MD_FILES = $(shell find . -type f -name '*.md')
HTML_FILES = $(patsubst %.md,%.html,$(MD_FILES))

all: $(HTML_FILES) makefile

# clean:
# 	rm -fv HTML_FILES

%.html: %.md style.css
	$(MARKDOWN) $< --output $@
