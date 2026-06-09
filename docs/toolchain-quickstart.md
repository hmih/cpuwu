# GateMate FPGA Toolchain Quickstart

Source: https://colognechip.com/programmable-logic/gatemate/gatemate-toolchain-quickstart/

## Installation

Download OSS CAD Suite, extract, and source the environment:

```bash
tar -xvf oss-cad-suite-<arch>-<build>.tgz
source environment
```

## Synthesis (Verilog)

```bash
yosys \
    -ql <logfile> \
    -p '
        read_verilog -defer -sv <sources>;
        synth_gatemate \
            -top <topmodule> \
            -luttree \
            -nomx8;
        write_json <netlist>.json;
        write_verilog <netlist>.v
    '
```

### `synth_gatemate` parameters

| Flag | Description |
|---|---|
| `-top <module>` | Top module name |
| `-luttree` | **Required** — enable LUT tree mapping |
| `-nomx8` | **Required** — disable MUX8 cells |
| `-nobram` | Disable BRAM cells |
| `-noaddf` | Disable full adder cells |
| `-nomult` | Disable multiplier cells |
| `-noflatten` | Don't flatten design |
| `-vlog <file>` | Write Verilog netlist |
| `-json <file>` | Write JSON netlist |

## Place & Route

```bash
nextpnr-himbaechel \
    --device CCGM1A1 \
    --json <filename>.json \
    -o ccf=<filename>.ccf \
    -o out=impl.txt \
    --router router2
```

Key options:
- `--device CCGM1A1` or `CCGM1A2`
- `--router router2` (always use router2)
- `-o ccf=<file>` — pin constraints (required)
- `-o out=<file>` — output text for bitstream
- `--sdc <file>` — optional timing constraints

## Bitstream

```bash
gmpack <input>.txt <output>.bit
```

## Programming

JTAG: `openFPGALoader -b gatemate_evb_jtag -f <bitfile>`
SPI:  `openFPGALoader -b gatemate_evb_spi -f <bitfile>`

Use `-m` for SRAM (volatile), `-f` for flash (persistent).
