# UART UVM Verification Environment (QuestaSim Starter)

A starter UVM testbench for a UART **receiver (RX)** IP. It drives serial UART frames into `rx`, then checks the DUT's parallel `data_out` and `data_valid` outputs.

> Important: `rtl/uart_rx_reference.sv` is a small reference/demo DUT so the starter project can be simulated standalone. Replace it with your actual UART RTL when available. Adapt the interface and monitor if your DUT uses different port names or timing.

## Features
- UVM sequence item, sequencer, driver, monitor, agent, environment and test
- 8-N-1 UART stimulus (1 start, 8 data bits LSB-first, 1 stop)
- Scoreboard compares transmitted stimulus with received parallel output
- QuestaSim compile/run script and a simple reference UART RX DUT

## Directory structure
```text
UVM_UART_Questa_Starter/
├── rtl/uart_rx_reference.sv
├── tb/uart_if.sv
├── tb/uart_uvm_pkg.sv
├── tb/tb_top.sv
├── sim/questa.do
├── sim/files.f
├── .gitignore
└── README.md
```

## Requirements
- QuestaSim/Questa Intel FPGA Edition with a SystemVerilog-capable simulator
- UVM library supported by your Questa installation (commonly UVM 1.2)
- A simulator license/configuration that enables UVM

## Run in QuestaSim
1. Open QuestaSim.
2. Change directory to this project folder.
3. In the Transcript, run:
   ```tcl
   do sim/questa.do
   ```
4. The script creates/uses `work`, compiles the reference DUT and testbench, then runs `run -all`.

If your installation does not recognize `+incdir+$UVM_HOME/src` or does not have `UVM_HOME` set, configure the UVM library path for your installation. Some Questa versions provide UVM precompiled libraries; consult your local Questa setup.

## Replace the reference DUT with your IP
The testbench expects this signal contract:
- Inputs: `clk`, active-low `rst_n`, serial input `rx`
- Outputs: `data_out[7:0]`, one-cycle `data_valid`

The serial format is 8 data bits, LSB first, one start bit and one stop bit. The default demo timing is `CLKS_PER_BIT=16`. Set the same value in the DUT and testbench driver. For your real UART, change this to match the configured clock and baud rate, or preferably add a configurable baud/clock parameter.

## Starter test
`uart_basic_test` sends 10 deterministic bytes. The scoreboard reports PASS/FAIL per byte and raises a UVM error on mismatch or timeout.

## Before publishing
- Replace demo/reference RTL with your own RTL only if you are allowed to share it.
- Do not upload confidential/company/university-restricted code, simulator licenses, passwords, or generated work-library files.
- Add your group members' names, roll numbers, project guide and institution details if appropriate.
- Add real simulation logs, waveforms and coverage reports after running the test. Do not claim coverage/results that you have not measured.

## Suggested next improvements
1. Add randomized data sequences and configurable baud rates.
2. Add reset-during-frame, back-to-back frames and invalid stop-bit tests.
3. Add functional coverage for data values, frame conditions and reset scenarios.
4. Add assertions for `data_valid` pulse width and protocol timing.
5. Add a UART TX agent if the DUT also transmits.


## Project Team

**Institution:** Malla Reddy University

| S. No. | Student Name | Roll Number |
|---:|---|---|
| 1 | SK. Mahimood Pasha | 2411EC010104 |
| 2 | CH. Rajesh | 2411EC010086 |

## Project Guide

Add your project guide's name here.

