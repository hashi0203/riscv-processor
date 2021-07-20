`default_nettype none
`include "def.sv"

module write
  ( input  wire         clk,
    input  wire         rstn,
    input  wire         enabled,

    input  instructions instr,
    input  wire [31:0]  reg_data,
    input  wire [31:0]  csr_data,

    output wire         reg_w_enabled,
    output wire [4:0]   reg_w_addr,
    output wire [31:0]  reg_w_data,
    output wire         csr_w_enabled,
    output wire [11:0]  csr_w_addr,
    output wire [31:0]  csr_w_data,
    output wire         completed );

  reg _completed;
  assign completed = _completed & !enabled;

  wire  _reg_w_enabled = enabled && (instr.rd != 5'b0);
  assign reg_w_enabled = _reg_w_enabled;
  assign reg_w_addr    = _reg_w_enabled ? instr.rd : 5'b0;
  assign reg_w_data    = _reg_w_enabled ? reg_data : 32'b0;

  wire  _csr_w_enabled = enabled && (instr.is_csr);
  assign csr_w_enabled = _csr_w_enabled;
  assign csr_w_addr    = _csr_w_enabled ? instr.imm : 12'b0;
  assign csr_w_data    = _csr_w_enabled ? csr_data : 32'b0;

  always @(posedge clk) begin
    if (rstn) begin
      if(enabled) begin
        _completed <= 1;
      end
    end else begin
      _completed <= 0;
    end
  end
endmodule

`default_nettype wire
