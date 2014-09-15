bin := run
src := ../src
gos := $(wildcard $(src)/*.go)

all: $(bin)

$(bin): $(gos)
	cd $(src) && go build -o $@
	mv $(src)/$@ $@

test:
	cd $(src) && go test

clean:
	rm -f $(bin)

.PHONY: all test clean
