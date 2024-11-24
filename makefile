SVFILES := Glasscell.sv Core.sv InstructionCache.sv MemoryEmulator.sv
VERILATOR_FLAGS := -O2 -sv --cc --exe --trace -x-assign fast --build -j 0 -LDFLAGS "-lm -lraylib"

all:
	verilator $(VERILATOR_FLAGS) $(SVFILES) Driver.cpp -o Glasscell --Mdir Build/ --top-module glasscell

run: all
	LIBGL_ALWAYS_SOFTWARE=1 ./Build/Glasscell
