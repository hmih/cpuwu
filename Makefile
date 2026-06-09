# GateMate FPGA Makefile
# ========================
#
# TARGETS:
#   all       synth → pnr → bitstream (default)
#   lint      Verilator lint check
#   sim       iverilog simulation + gtkwave viewer
#   synth     Yosys synthesis → netlist JSON
#   pnr       nextpnr-himbaechel place & route → impl.txt
#   bitstream gmpack → bitstream (.bit)
#   flash     openFPGALoader → program device (SPI flash)
#   view      Yosys show → schematic PNG (needs graphviz)
#   clean     Remove generated files
#   mrproper  clean + nix store gc
#
# Prerequisites: vendor/oss-cad-suite (source environment first)
#
# CONFIGURATION:
#   DEVICE     GateMate device (default: CCGM1A1)
#   BOARD      openFPGALoader board flag (default: gatemate_evb_spi)

TOP       := hello
SRC       := src/$(TOP).v
TB        := test/tb_$(TOP).v
OUT       := gen
DEVICE    ?= CCGM1A1
BOARD     ?= olimex_gatemateevb

# Derived output paths
JSON      := $(OUT)/$(TOP).json
IMPL      := $(OUT)/impl.txt
BIT       := $(OUT)/$(TOP).bit
VVP       := $(OUT)/$(TOP)_tb.vvp
VCD       := $(OUT)/$(TOP)_tb.vcd
SCHEM     := $(OUT)/$(TOP)_schem

_dir      := $(shell mkdir -p $(OUT))

# OSS CAD Suite (assumed in vendor/)
OSS_ENV   := vendor/oss-cad-suite/environment

# ── Default ──────────────────────────────────────────────────────────────────
.PHONY: all
all: $(BIT)

# ── Lint ─────────────────────────────────────────────────────────────────────
.PHONY: lint
lint:
	@echo "==> Verilator lint"
	verilator --lint-only -Wall -Wno-DECLFILENAME $(SRC)
	@echo "==> Yosys hierarchy check"
	. $(OSS_ENV) && yosys -p "read_verilog $(SRC); hierarchy -check -top $(TOP)" -q

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
synth: $(JSON)

$(JSON): synth.ys $(SRC)
	@mkdir -p $(OUT)
	@echo "==> Yosys synthesis (GateMate)"
	. $(OSS_ENV) && yosys -q synth.ys

# ── Place & Route ────────────────────────────────────────────────────────────
.PHONY: pnr
pnr: $(IMPL)

$(IMPL): $(JSON) pins.ccf
	@echo "==> nextpnr-himbaechel ($(DEVICE))"
	. $(OSS_ENV) && nextpnr-himbaechel \
		--device $(DEVICE) \
		--json $< \
		-o ccf=$(word 2,$^) \
		-o out=$@ \
		--router router2

# ── Bitstream ────────────────────────────────────────────────────────────────
.PHONY: bitstream
bitstream: $(BIT)

$(BIT): $(IMPL)
	@echo "==> gmpack"
	. $(OSS_ENV) && gmpack $< $@

# ── Flash ────────────────────────────────────────────────────────────────────
.PHONY: flash
flash: $(BIT)
	@echo "==> Flashing $(DEVICE) via $(BOARD)"
	. $(OSS_ENV) && openFPGALoader -b $(BOARD) -f $<

# ── Inspect ──────────────────────────────────────────────────────────────────
.PHONY: view
view: $(JSON)
	. $(OSS_ENV) && yosys -p "read_json $(JSON); show -format png -prefix $(SCHEM)"

# ── Cleanup ──────────────────────────────────────────────────────────────────
.PHONY: clean
clean:
	rm -rf $(OUT)

.PHONY: mrproper
mrproper: clean
	nix-collect-garbage
