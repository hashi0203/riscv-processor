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

	assign r_data = mem[addr];

	always @(posedge clk) begin
		if(rstn) begin
			// if (r_enabled) begin
			// 	r_data <= mem[addr];
			// end else if(w_enabled) begin
			if(w_enabled) begin
				mem[addr] <= w_data;
			end
		end
	end

endmodule

`default_nettype wire