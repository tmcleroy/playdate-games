.PHONY: clean
.PHONY: all
.PHONY: run

SDKBIN=../../playdate/bin
SIM="Playdate Simulator"

all: screenclimb.pdx

screenclimb.pdx: Source/main.lua
	$(SDKBIN)/pdc Source screenclimb.pdx

clean:
	rm -rf screenclimb.pdx

run: all
	$(SDKBIN)/$(SIM).app/Contents/MacOS/$(SIM) screenclimb.pdx

