.SUFFIXES: .hex

EXAMPLES=$(wildcard examples/*.s)
EXAMPLE_BUILDS=$(EXAMPLES:examples/%.s=build/%.hex)

run: cpu_inputs build/fib.hex build/cpu.vvp
	./build/cpu.vvp

all: $(EXAMPLE_BUILDS) cpu_inputs

clean:
	rm -f build/*.bin build/*.hex

cpu_inputs: build/instruction_rom.bin

build/instruction_rom.bin: make_micro_instr.py
	python3 make_micro_instr.py > build/instruction_rom.bin

$(EXAMPLE_BUILDS): build/%.hex: examples/%.s
	python3 assemble.py < $< > $@

build/%.vvp: %.v
	iverilog -o $@ $<
