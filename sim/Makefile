RV_TOOLCHAIN ?= riscv64-unknown-elf  # Toolchain prefix (e.g. riscv32-unknown-elf, riscv64-unknown-linux-gnu)
PROG_NAME ?= test.c

RV_TOOLCHAIN := $(strip $(RV_TOOLCHAIN))
CC := $(RV_TOOLCHAIN)-gcc

.PHONY: build test help

all: help

build:
	$(CC) -march=rv32i -mabi=ilp32 -nostdlib -nostartfiles -mstrict-align -Tlink.ld main.s $(PROG_NAME) -o test
	
test:
	expect spike_get_log.exp > "spike_log.log"
	python3 run_test.py

help:
	@echo "----------------------------------------------------------------"
	@echo "  Targets:"
	@echo "  help       - Show this help message"
	@echo "  build      - Compile C program for bare-metal RISC-V (using RV_TOOLCHAIN)"
	@echo "  test       - Run tests with Spike simulator and Cocotb"
	@echo "  clean      - Remove compiled binaries and log files"
	@echo "  clean_c    - Remove generated C source and header files"
	@echo "  clean_all  - Remove all generated files (clean + clean_c)"
	@echo "----------------------------------------------------------------"
	@echo "Configuration variables:"
	@echo "  RV_TOOLCHAIN - RISC-V toolchain prefix (default: riscv64-unknown-elf)"
	@echo "  PROG_NAME    - C source file to compile (default: test.c)"

clean:
	rm -f test
	rm -f *.log

clean_c:
	rm -f *.c
	rm -f *.h

clean_all: 
	$(MAKE) clean clean_c
