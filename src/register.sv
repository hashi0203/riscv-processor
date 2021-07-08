`default_nettype none
`include "def.sv"

module register
  (input  wire        clk,
   input  wire        rstn,
   input  wire        r_enabled,

   input  wire [4:0]  rs1_addr,
   input  wire [4:0]  rs2_addr,

   output reg  [31:0] rs1_val,
   output reg  [31:0] rs2_val,

   input  wire        w_enabled,
   input  wire [4:0]  w_addr,
   input  wire [31:0] w_data,

	 output reg  [31:0] regs_out [31:0] );

	reg [31:0] regs [31:0];

	integer i;
	initial begin
		for (i=0; i<32; i++) begin
				if (i == 2) begin
					regs[2] <= 32'd512;
				end else begin
					regs[i] <= 0;
				end
		end
	end

	always @(posedge clk) begin
		if(rstn) begin
			if (r_enabled) begin
				rs1_val <= (w_enabled && w_addr != 0 && w_addr == rs1_addr) ? w_data : regs[rs1_addr];
				rs2_val <= (w_enabled && w_addr != 0 && w_addr == rs2_addr) ? w_data : regs[rs2_addr];
			end
			if(w_enabled) begin
				regs[w_addr] <= w_data;
			end
		end else begin
			rs1_val <= 0;
			rs2_val <= 0;
		end
		regs_out <= regs;
	end

endmodule

`default_nettype wire