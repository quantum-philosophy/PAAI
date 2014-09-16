bin := run
src := ../src
gos := $(wildcard $(src)/*.go)

cases := 002_020 002_040 004_080

all: $(bin)

$(bin): $(gos)
	cd $(src) && go build -o $@
	mv $(src)/$@ $@

$(cases): $(bin)
	./run construct -config assets/$@.json -output construct_$@.mat
	./run assess -config assets/$@.json -input construct_$@.mat -output assess_$@.mat

test:
	cd $(src) && go test

clean:
	rm -f $(bin) *.mat

.PHONY: all test clean
