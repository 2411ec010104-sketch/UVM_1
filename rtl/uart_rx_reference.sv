// DEMO / REFERENCE UART RX DUT.
// Replace this module with your actual UART receiver RTL for project verification.
module uart_rx_reference #(
  parameter int CLKS_PER_BIT = 16
)(
  input  logic       clk,
  input  logic       rst_n,
  input  logic       rx,
  output logic [7:0] data_out,
  output logic       data_valid
);
  typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
  state_t state;
  integer count;
  integer bit_index;
  logic [7:0] shift_reg;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      state      <= IDLE;
      count      <= 0;
      bit_index  <= 0;
      shift_reg  <= '0;
      data_out   <= '0;
      data_valid <= 1'b0;
    end else begin
      data_valid <= 1'b0;
      case (state)
        IDLE: begin
          count <= 0;
          if (rx == 1'b0)
            state <= START;
        end
        START: begin
          if (count == (CLKS_PER_BIT/2)-1) begin
            count <= 0;
            if (rx == 1'b0) begin
              bit_index <= 0;
              state <= DATA;
            end else state <= IDLE;
          end else count <= count + 1;
        end
        DATA: begin
          if (count == CLKS_PER_BIT-1) begin
            count <= 0;
            shift_reg[bit_index] <= rx;
            if (bit_index == 7) state <= STOP;
            else bit_index <= bit_index + 1;
          end else count <= count + 1;
        end
        STOP: begin
          if (count == CLKS_PER_BIT-1) begin
            count <= 0;
            if (rx == 1'b1) begin
              data_out <= shift_reg;
              data_valid <= 1'b1;
            end
            state <= IDLE;
          end else count <= count + 1;
        end
        default: state <= IDLE;
      endcase
    end
  end
endmodule
