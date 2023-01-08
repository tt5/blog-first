IN := $(wildcard *.code)
OUT    := $(IN:.code=.liquid)

.PHONY: all

all: $(OUT)

$(OUT): %.liquid: %.code
	node ../../../prism.js $^ > $^.liquid
#  @touch $@
