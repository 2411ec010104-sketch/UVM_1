`timescale 1ns/1ps
module tb_top;
  import uvm_pkg::*;
  import uart_uvm_pkg::*;

  bit clk = 0;
  always #5 clk = ~clk;

  uart_if uart_vif(clk);

  // Demo DUT. Replace with your actual DUT instance and connect its ports.
  uart_rx_reference #(.CLKS_PER_BIT(CLKS_PER_BIT)) dut (
    .clk       (clk),
    .rst_n     (uart_vif.rst_n),
    .rx        (uart_vif.rx),
    .data_out  (uart_vif.data_out),
    .data_valid(uart_vif.data_valid)
  );

  initial begin
    uart_vif.rst_n = 1'b0;
    uart_vif.rx = 1'b1;
    repeat (5) @(posedge clk);
    uart_vif.rst_n = 1'b1;
  end

  initial begin
    uvm_config_db#(virtual uart_if)::set(null, "*", "vif", uart_vif);
    run_test("uart_basic_test");
  end

  initial begin
    #200000;
    $fatal(1, "Global simulation timeout");
  end
endmodule
