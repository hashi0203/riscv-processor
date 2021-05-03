`default_nettype none
`include "def.sv"

module execute
	( input  wire         clk,
		input  wire         rstn,

    input  wire         enabled,
		input  instructions instr,
		input  reg [31:0]   rs1,
		input  reg [31:0]   rs2,
		// input   reg          frs1,
		// input   reg          frs2,

		output wire         completed,
		output instructions instr_out,
		output reg [31:0]   rs1_out,
		output reg [31:0]   rs2_out,
		// output reg          frs1_out,
		// output reg          frs2_out,

		output wire [31:0]  result );

		// wire _completed = ((instr_n.rv32f && fpu_completed)
		// 										|| (!instr_n.rv32f && alu_completed));
		wire _completed = 1;
		assign completed = _completed & !enabled;

		assign result = $signed(rs1) + $signed(rs2);

		always @(posedge clk) begin
			if (rstn) begin
				if (enabled) begin
					instr_out <= instr;
					rs1_out <= rs1;
					rs2_out <= rs2;
				end
			end
		end
endmodule

`default_nettype wire
