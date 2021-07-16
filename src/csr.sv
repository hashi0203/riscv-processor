`default_nettype none
`include "def.sv"

module csr
  ( input  wire        clk,
    input  wire        rstn,

    input  wire        r_enabled,
    input  wire [11:0] csr_addr,
    output wire [31:0] csr_data,

    input  wire        w_enabled,
    input  wire [4:0]  w_addr,
    input  wire [31:0] w_data );

  reg [31:0] csregs [4095:0];

  integer i;
  initial begin
    for (i=0; i<4096; i++) begin
			csregs[i] <= 0;
    end
  end

  assign csr_data = (w_enabled && w_addr == csr_addr) ? w_data : csregs[csr_addr];

  always @(posedge clk) begin
    if(rstn) begin
      if(w_enabled) begin
        csregs[w_addr] <= w_data;
      end
    end
  end
endmodule

`default_nettype wire