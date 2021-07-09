`default_nettype none
`include "def.sv"

module execute
	( input  wire         clk,
		input  wire         rstn,

    input  wire         enabled,
		input  instructions instr,
		input  reg [31:0]   rs1,
		input  reg [31:0]   rs2,

		output wire         completed,
		output instructions instr_out,
		// output reg [31:0]   rs1_out,
		// output reg [31:0]   rs2_out,

		output wire [31:0]  rd,
		output wire         is_jump,
		output wire [31:0]  jump_dest );

		wire [31:0] alu_rd;
		wire        alu_completed;
		alu _alu
			( .clk(clk),
				.rstn(rstn),
				.enabled(enabled),
				.instr(instr),
				.rs1(rs1),
				.rs2(rs2),
				.completed(alu_completed),
				.rd(alu_rd) );

		// wire _completed = ((instr_n.rv32f && fpu_completed)
		// 										|| (!instr_n.rv32f && alu_completed));
		wire _completed = 1;
		assign completed = _completed & !enabled;

		reg [31:0] r_data;
		memory _memory
			( .clk(clk),
				.rstn(rstn),
				.base(rs1),
				.offset(instr.imm),

				.r_enabled(instr.lw),
				.r_data(r_data),
				.w_enabled(instr.sw),
				.w_data(rs2) );

		assign rd = instr.lw ? r_data : alu_rd;
		assign is_jump = instr_out.jal || instr_out.jalr || (instr_out.is_conditional_jump && alu_rd == 32'b1);
		assign jump_dest = instr_out.jal  ? $signed(instr_out.pc) + $signed($signed(instr_out.imm) >>> 2) :
											 instr_out.jalr ? $signed(rs1) + $signed($signed(instr_out.imm) >>> 2) :
											 instr_out.is_conditional_jump && alu_rd == 32'b1 ? $signed(instr_out.pc) + $signed($signed(instr_out.imm) >>> 2) :
											 instr_out.pc + 1;

		always @(posedge clk) begin
			if (rstn) begin
				if (enabled) begin
					instr_out <= instr;
				end
			end
		end
endmodule

`default_nettype wire
