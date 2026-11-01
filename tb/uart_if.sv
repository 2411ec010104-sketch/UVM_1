interface uart_if(input logic clk);
  logic       rst_n;
  logic       rx;
  logic [7:0] data_out;
  logic       data_valid;

  // Driver/monitor clocking is intentionally simple for this starter.
  modport dut (
    input  clk, rst_n, rx,
    output data_out, data_valid
  );
endinterface
