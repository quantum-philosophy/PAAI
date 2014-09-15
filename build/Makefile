bin := run
src := ../src
gos := $(wildcard $(src)/*.go)

all: $(bin)

$(bin): $(gos)
	cd $(src) && go build -o $@
	mv $(src)/$@ $@

clean:
	rm -f $(bin)

.PHONY: all clean
