`default_nettype none
`include "def.sv"

module memory
  (input  wire        clk,
   input  wire        rstn,
   input  wire [31:0] base,
   input  wire [31:0] offset,

   input  wire        r_enabled,
   output wire [31:0] r_data,
   input  wire        w_enabled,
   input  wire [31:0] w_data);

  reg  [31:0] mem [0:1023];
  wire [31:0] addr = $signed(($signed(base) + $signed(offset))) >>> 2;

  assign r_data = (rstn && r_enabled) ? mem[addr] : 32'b0;

  integer i;
  initial begin
    for (i=0; i<1024; i++) begin
        mem[i] <= 0;
    end
  end

  always @(posedge clk) begin
    if(rstn) begin
      if(w_enabled) begin
        mem[addr] <= w_data;
      end
    end
  end

endmodule

`default_nettype wire