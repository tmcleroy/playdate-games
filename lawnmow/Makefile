.PHONY: clean
.PHONY: all
.PHONY: run

SDKBIN=../../playdate/bin
SIM="Playdate Simulator"

all: lawnmow.pdx

lawnmow.pdx: src/main.lua
	$(SDKBIN)/pdc src lawnmow.pdx

clean:
	rm -rf lawnmow.pdx

run: all
	$(SDKBIN)/$(SIM).app/Contents/MacOS/$(SIM) lawnmow.pdx

