subdirs := $(wildcard */)
vasm_sources := $(wildcard *.asm) $(wildcard $(addsuffix *.asm, $(subdirs)))
vasm_objects := $(addprefix obj/, $(patsubst %.asm,%.o,$(notdir $(vasm_sources))))
objects := $(vasm_objects)
deps := $(objects:.o=.d)

program = out/a
OUT = $(program)
CC = m68k-amiga-elf-gcc
VASM = vasmm68k_mot
DEBUG = 1

ifdef OS
	WINDOWS = 1
	SHELL = cmd.exe
endif

CCFLAGS = -g -MP -MMD -m68000 -Ofast -nostdlib -Wextra -Wno-unused-function -Wno-volatile-register-var -fomit-frame-pointer -fno-tree-loop-distribution -flto -fwhole-program -fno-exceptions
LDFLAGS = -Wl,--emit-relocs,-Ttext=0,-Map=$(OUT).map
VASMFLAGS = -m68000 -Felf -opt-fconst -nowarn=62 -dwarf=3 -x -DDEBUG=$(DEBUG)

all: $(OUT).exe

dist: DEBUG = 0
dist: $(OUT).shrinkled.exe

$(OUT).shrinkled.exe: $(OUT).exe
	Shrinkler -h -9 -T decrunch.txt $< $@

$(OUT).exe: $(OUT).elf
	$(info Elf2Hunk $(program).exe)
	@elf2hunk $(OUT).elf $(OUT).exe -s

$(OUT).elf: $(objects)
	$(info Linking $(program).elf)
	$(CC) $(CCFLAGS) $(LDFLAGS) $(objects) -o $@
	@m68k-amiga-elf-objdump --disassemble --no-show-raw-ins --visualize-jumps -S $@ >$(OUT).s

clean:
	$(info Cleaning...)
ifdef WINDOWS
	@del /q obj\* out\*
else
	@$(RM) obj/* out/*
endif

-include $(deps)

$(vasm_objects): obj/%.o : %.asm
	$(info Assembling $<)
	@$(VASM) $(VASMFLAGS) -o $@ $(CURDIR)/$<

$(deps): obj/%.d : %.asm
	$(info Building dependencies for $<)
	$(VASM) $(VASMFLAGS) -quiet -depend=make -o $(patsubst %.d,%.o,$@) $(CURDIR)/$< > $@

.PHONY: all clean dist
