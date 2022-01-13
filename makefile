MARKDOWN = pandoc -s includes.yaml
MD_FILES = $(shell find . -type f -name '*.md')
HTML_FILES = $(patsubst %.md,%.html,$(MD_FILES))

all: $(HTML_FILES)

clean:
	rm -v $(HTML_FILES)

%.html: %.md style.css makefile includes.yaml
	$(MARKDOWN) $< --output $@
