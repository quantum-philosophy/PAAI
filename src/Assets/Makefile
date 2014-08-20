TGFF ?= tgff

tgffs := $(patsubst %.tgffopt,%.tgff,$(wildcard *.tgffopt))

all: $(tgffs)

%.tgff: %.tgffopt
	$(TGFF) $*

clean:
	$(RM) *.vcg *.eps *.tgff

.PHONY: all
