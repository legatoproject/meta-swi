# License: Creative Commons Zero 1.0 Universal (CC0)

SRC := $(shell pwd)

all:
	$(MAKE) -C $(KERNEL_SRC) M=$(SRC) outputmakefile

# Catch-all rule matches all conceivable targets: clean, tests, etc.
%:
	@echo "$@" dummy target invoked
