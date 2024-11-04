SVFILES := Glasscell.sv Core.sv RegisterBank.sv ALU2.sv ALU1.sv Comparator.sv InstructionCache.sv DataCache.sv
VERILATOR_FLAGS := -O2 -sv --cc --exe --trace -x-assign fast --build -j 0 -LDFLAGS "-lm -lraylib"

all:
	verilator $(VERILATOR_FLAGS) $(SVFILES) Driver.cpp -o Glasscell --Mdir Build/ --top-module glasscell

run: all
	LIBGL_ALWAYS_SOFTWARE=1 ./Build/Glasscell
