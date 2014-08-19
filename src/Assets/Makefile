TGFF ?= tgff

tgffs := $(patsubst %.tgffopt,%.tgff,$(wildcard *.tgffopt))

all: $(tgffs)

%.tgff:
	$(TGFF) $*

clean:
	$(RM) *.vcg *.eps *.tgff

.PHONY: all
