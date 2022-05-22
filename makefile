MARKDOWN = pandoc --from markdown+auto_identifiers -s includes.yaml --lua-filter=anchor-links.lua
MD_FILES = $(shell find . -type f -name '*.md' | grep -v README.md)
RSS_FILE = $(shell find blog/*/ -type f -name 'index.md')
HTML_FILES = $(patsubst %.md,%.html,$(MD_FILES))

all: $(HTML_FILES) ./blog/index.xml

clean:
	rm -v $(HTML_FILES)
	rm ./blog/index.xml

%.html: %.md makefile includes.yaml anchor-links.lua
	$(MARKDOWN) $< --output $@

./blog/index.xml: $(RSS_FILE) makefile mkdwnrss.sh
	./mkdwnrss.sh $(RSS_FILE) > blog/index.xml
