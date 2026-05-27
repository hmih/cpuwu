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
TB       := src/tb_$(TOP).v

BOARD    ?= ulx3s
DEVICE   ?= 25k
PACKAGE  ?= CABGA381
SPEED    ?= 6

# ── Default ──────────────────────────────────────────────────────────────────
.PHONY: all
all: $(TOP).bit

# ── Lint ─────────────────────────────────────────────────────────────────────
.PHONY: lint
lint:
	@echo "==> Verilator lint"
	verilator --lint-only -Wall -Wno-DECLFILENAME $(SRC)
	@echo "==> Yosys hierarchy check"
	yosys -p "read_verilog $(SRC); hierarchy -check -top $(TOP)" -q

# ── Simulation ───────────────────────────────────────────────────────────────
.PHONY: sim
sim: $(TOP)_tb.vvp
	@echo "==> Running iverilog"
	vvp $<
	@echo "==> Opening gtkwave"
	gtkwave $(TOP)_tb.vcd $(TOP).gtkw &

$(TOP)_tb.vvp: $(TB) $(SRC)
	iverilog -g2012 -Wall -o $@ $(SRC) $(TB)

# ── Synthesis ────────────────────────────────────────────────────────────────
.PHONY: synth
synth: $(TOP).json $(TOP).cas

$(TOP).json $(TOP).cas $(TOP).iss.json: synth.ys $(SRC)
	@echo "==> Yosys synthesis"
	yosys -q synth.ys

# ── Place & Route ────────────────────────────────────────────────────────────
.PHONY: pnr
pnr: $(TOP).config

$(TOP).config: $(TOP).json $(TOP).lpf
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
bitstream: $(TOP).bit

$(TOP).bit: $(TOP).config
	@echo "==> ecppack"
	ecppack --input $< --bit $@

# ── Flash ────────────────────────────────────────────────────────────────────
.PHONY: flash
flash: $(TOP).bit
	@echo "==> Flashing to $(BOARD)"
	openFPGALoader --board=$(BOARD) $<

# ── Inspect ──────────────────────────────────────────────────────────────────
.PHONY: view
view: $(TOP).json
	yosys -p "read_json $(TOP).json; show -format png -prefix $(TOP)_schem"

.PHONY: stats
stats: $(TOP).cas
	@cat $<

.PHONY: check
check:
	yosys -p "read_verilog $(SRC); hierarchy -check -top $(TOP); proc; check" -q
	@echo "Design checks passed."

# ── Cleanup ──────────────────────────────────────────────────────────────────
.PHONY: clean
clean:
	rm -f $(TOP).json $(TOP).cas $(TOP).iss.json
	rm -f $(TOP).config $(TOP).bit
	rm -f $(TOP)_tb.vvp $(TOP)_tb.vcd
	rm -f $(TOP)_schem.png $(TOP)_schem.dot

.PHONY: mrproper
mrproper: clean
	nix-collect-garbage
