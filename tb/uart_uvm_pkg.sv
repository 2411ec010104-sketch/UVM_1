package uart_uvm_pkg;
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // Must match CLKS_PER_BIT in the DUT.
  parameter int CLKS_PER_BIT = 16;

  class uart_seq_item extends uvm_sequence_item;
    rand bit [7:0] data;

    `uvm_object_utils_begin(uart_seq_item)
      `uvm_field_int(data, UVM_ALL_ON)
    `uvm_object_utils_end

    function new(string name = "uart_seq_item");
      super.new(name);
    endfunction
  endclass

  class uart_sequencer extends uvm_sequencer #(uart_seq_item);
    `uvm_component_utils(uart_sequencer)
    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction
  endclass

  class uart_driver extends uvm_driver #(uart_seq_item);
    `uvm_component_utils(uart_driver)
    virtual uart_if vif;
    uvm_analysis_port #(uart_seq_item) expected_ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      expected_ap = new("expected_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "uart_if virtual interface was not set")
    endfunction

    task drive_bit(bit value);
      vif.rx <= value;
      repeat (CLKS_PER_BIT) @(posedge vif.clk);
    endtask

    task run_phase(uvm_phase phase);
      uart_seq_item expected;
      vif.rx <= 1'b1;
      wait (vif.rst_n === 1'b1);
      forever begin
        seq_item_port.get_next_item(req);
        // UART 8-N-1 frame: idle high, start low, 8 LSB-first data bits, stop high.
        drive_bit(1'b0);
        for (int i = 0; i < 8; i++)
          drive_bit(req.data[i]);
        drive_bit(1'b1);
        expected = uart_seq_item::type_id::create("expected");
        expected.copy(req);
        expected_ap.write(expected);
        seq_item_port.item_done();
      end
    endtask
  endclass

  class uart_monitor extends uvm_component;
    `uvm_component_utils(uart_monitor)
    virtual uart_if vif;
    uvm_analysis_port #(uart_seq_item) actual_ap;

    function new(string name, uvm_component parent);
      super.new(name, parent);
      actual_ap = new("actual_ap", this);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      if (!uvm_config_db#(virtual uart_if)::get(this, "", "vif", vif))
        `uvm_fatal("NOVIF", "uart_if virtual interface was not set")
    endfunction

    task run_phase(uvm_phase phase);
      uart_seq_item item;
      forever begin
        @(posedge vif.clk);
        if (vif.rst_n && vif.data_valid) begin
          item = uart_seq_item::type_id::create("observed");
          item.data = vif.data_out;
          actual_ap.write(item);
          `uvm_info("MON", $sformatf("Observed data 0x%02h", item.data), UVM_MEDIUM)
        end
      end
    endtask
  endclass

  class uart_agent extends uvm_agent;
    `uvm_component_utils(uart_agent)
    uart_sequencer sequencer;
    uart_driver    driver;
    uart_monitor   monitor;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      monitor = uart_monitor::type_id::create("monitor", this);
      if (get_is_active() == UVM_ACTIVE) begin
        sequencer = uart_sequencer::type_id::create("sequencer", this);
        driver = uart_driver::type_id::create("driver", this);
      end
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      if (get_is_active() == UVM_ACTIVE)
        driver.seq_item_port.connect(sequencer.seq_item_export);
    endfunction
  endclass

  class uart_scoreboard extends uvm_component;
    `uvm_component_utils(uart_scoreboard)
    uvm_tlm_analysis_fifo #(uart_seq_item) expected_fifo;
    uvm_tlm_analysis_fifo #(uart_seq_item) actual_fifo;
    int checked_count = 0;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      expected_fifo = new("expected_fifo", this);
      actual_fifo = new("actual_fifo", this);
    endfunction

    task run_phase(uvm_phase phase);
      uart_seq_item expected, actual;
      forever begin
        expected_fifo.get(expected);
        actual_fifo.get(actual);
        checked_count++;
        if (expected.data !== actual.data)
          `uvm_error("UART_MISMATCH",
            $sformatf("Byte %0d mismatch: expected=0x%02h actual=0x%02h",
                      checked_count, expected.data, actual.data))
        else
          `uvm_info("UART_MATCH",
            $sformatf("Byte %0d PASS: 0x%02h", checked_count, actual.data),
            UVM_LOW)
      end
    endtask

    function void report_phase(uvm_phase phase);
      `uvm_info("UART_SB", $sformatf("Total bytes checked: %0d", checked_count), UVM_LOW)
    endfunction
  endclass

  class uart_env extends uvm_env;
    `uvm_component_utils(uart_env)
    uart_agent agent;
    uart_scoreboard scoreboard;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      agent = uart_agent::type_id::create("agent", this);
      scoreboard = uart_scoreboard::type_id::create("scoreboard", this);
    endfunction

    function void connect_phase(uvm_phase phase);
      super.connect_phase(phase);
      agent.monitor.actual_ap.connect(scoreboard.actual_fifo.analysis_export);
      agent.driver.expected_ap.connect(scoreboard.expected_fifo.analysis_export);
    endfunction
  endclass

  class uart_basic_sequence extends uvm_sequence #(uart_seq_item);
    `uvm_object_utils(uart_basic_sequence)
    function new(string name = "uart_basic_sequence");
      super.new(name);
    endfunction

    task body();
      uart_seq_item item;
      bit [7:0] values[10] = '{8'h00, 8'hFF, 8'h55, 8'hAA, 8'h01,
                               8'h80, 8'h7F, 8'hA5, 8'h3C, 8'hC3};
      foreach (values[i]) begin
        item = uart_seq_item::type_id::create($sformatf("item_%0d", i));
        start_item(item);
        item.data = values[i];
        finish_item(item);
      end
    endtask
  endclass

  class uart_basic_test extends uvm_test;
    `uvm_component_utils(uart_basic_test)
    uart_env env;

    function new(string name, uvm_component parent);
      super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
      super.build_phase(phase);
      env = uart_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
      uart_basic_sequence seq;
      phase.raise_objection(this);
      seq = uart_basic_sequence::type_id::create("seq");
      seq.start(env.agent.sequencer);
      // Allow the last received byte to reach the scoreboard.
      repeat (CLKS_PER_BIT * 12) @(posedge env.agent.driver.vif.clk);
      phase.drop_objection(this);
    endtask
  endclass
endpackage
