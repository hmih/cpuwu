# cpuwu FPGA Makefile
# =====================
#
# TARGETS:
#   all       synth → pnr → bitstream (default)
#   lint      Verilator lint check
#   sim       iverilog simulation + gtkwave viewer
#   synth     Yosys synthesis → netlist JSON + CAS stats
#   pnr       nextpnr-ecp5 place & route → text config
#   bitstream ecppack → bitstream (.bit), ready to flash
#   flash     openFPGALoader → program device
#   view      Yosys show → schematic PNG (needs graphviz)
#   stats     Print cell assignment statistics
#   check     Yosys hierarchy check
#   clean     Remove generated files
#   mrproper  clean + nix store gc on project paths
#
# CONFIGURATION:
#   BOARD     target board for openFPGALoader (default: ulx3s)
#   DEVICE    ECP5 device (default: 25k)
#   PACKAGE   package (default: CABGA381)
#   SPEED     speed grade (default: 6)

TOP      := hello
SRC      := src/$(TOP).v
TB       := test/tb_$(TOP).v
OUT      := gen

BOARD    ?= ulx3s
DEVICE   ?= 25k
PACKAGE  ?= CABGA381
SPEED    ?= 6

# Derived output paths
JSON     := $(OUT)/$(TOP).json
CAS      := $(OUT)/$(TOP).cas
ISS_JSON := $(OUT)/$(TOP).iss.json
CONFIG   := $(OUT)/$(TOP).config
BIT      := $(OUT)/$(TOP).bit
VVP      := $(OUT)/$(TOP)_tb.vvp
VCD      := $(OUT)/$(TOP)_tb.vcd
SCHEM    := $(OUT)/$(TOP)_schem

_dir     := $(shell mkdir -p $(OUT))

# ── Default ──────────────────────────────────────────────────────────────────
.PHONY: all
all: $(BIT)

# ── Lint ─────────────────────────────────────────────────────────────────────
.PHONY: lint
lint:
	@echo "==> Verilator lint"
	verilator --lint-only -Wall -Wno-DECLFILENAME $(SRC)
	@echo "==> Yosys hierarchy check"
	yosys -p "read_verilog $(SRC); hierarchy -check -top $(TOP)" -q

# ── Simulation ───────────────────────────────────────────────────────────────
.PHONY: sim
sim: $(VVP)
	@echo "==> Running iverilog"
	vvp $<
	@echo "==> Opening gtkwave"
	gtkwave $(VCD) wave.gtkw &

$(VVP): $(TB) $(SRC)
	@mkdir -p $(OUT)
	iverilog -g2012 -Wall -o $@ $(SRC) $(TB)

# ── Synthesis ────────────────────────────────────────────────────────────────
.PHONY: synth
synth: $(JSON) $(CAS)

$(JSON) $(CAS) $(ISS_JSON): synth.ys $(SRC)
	@mkdir -p $(OUT)
	@echo "==> Yosys synthesis"
	yosys -q synth.ys

# ── Place & Route ────────────────────────────────────────────────────────────
.PHONY: pnr
pnr: $(CONFIG)

$(CONFIG): $(JSON) pins.lpf
	@echo "==> nextpnr place & route ($(DEVICE)-$(PACKAGE))"
	nextpnr-ecp5 \
		--json $< \
		--lpf $(word 2,$^) \
		--textcfg $@ \
		--$(DEVICE) \
		--package $(PACKAGE) \
		--speed $(SPEED) \
		--lpf-allow-unconstrained

# ── Bitstream ────────────────────────────────────────────────────────────────
.PHONY: bitstream
bitstream: $(BIT)

$(BIT): $(CONFIG)
	@echo "==> ecppack"
	ecppack --input $< --bit $@

# ── Flash ────────────────────────────────────────────────────────────────────
.PHONY: flash
flash: $(BIT)
	@echo "==> Flashing to $(BOARD)"
	openFPGALoader --board=$(BOARD) $<

# ── Inspect ──────────────────────────────────────────────────────────────────
.PHONY: view
view: $(JSON)
	yosys -p "read_json $(JSON); show -format png -prefix $(SCHEM)"

.PHONY: stats
stats: $(CAS)
	@cat $<

.PHONY: check
check:
	yosys -p "read_verilog $(SRC); hierarchy -check -top $(TOP); proc; check" -q
	@echo "Design checks passed."

# ── Cleanup ──────────────────────────────────────────────────────────────────
.PHONY: clean
clean:
	rm -rf $(OUT)

.PHONY: mrproper
mrproper: clean
	nix-collect-garbage
