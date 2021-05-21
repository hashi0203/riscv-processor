`default_nettype none
`include "def.sv"

module core
	( input wire      clk,
		input wire      rstn,

		output reg [31:0] pc_out,
		output reg [1:0] state_out,
		output reg [31:0] register_out [31:0] );

		reg [31:0]      pc;

		reg [1:0]       state;

		reg [31:0] inst_mem [0:7] = '{
			32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
			32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
			32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
			32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
			32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
			32'b00000000001000011000000110110011,  // ADD 3(rs1) + 2(rs2) = 3(rd)
			32'b00000000001000011000000110110011,  // ADD 3(rs1) + 2(rs2) = 3(rd)
			32'b00000000001000011000001010110011  // ADD 3(rs1) + 2(rs2) = 5(rd)
		};

		reg [31:0] register [31:0];


		// fetch
		reg  fetch_enabled;
		reg  fetch_rstn;
		// wire fetch_completed;
		reg fetch_completed;

		// wire [31:0] pc_fd_out;
		// wire [31:0] instr_fd_out;


		// decode
		reg  decode_enabled;
		reg  decode_rstn;
		wire decode_completed;

		reg [31:0] pc_fd_in;
		reg [31:0] instr_fd_in;

		instructions instr_de_out;
		wire [4:0] rs1_num;
		wire [4:0] rs2_num;

		decode _decode
			( .clk(clk),
				.rstn(rstn & decode_rstn),
				.pc(pc_fd_in),
				.enabled(decode_enabled),
				.instr_raw(instr_fd_in),

				.completed(decode_completed),
				.instr(instr_de_out),
				.rs1(rs1_num),
				.rs2(rs2_num) );

		// execute
		reg  execute_enabled;
		reg  execute_rstn;
		wire execute_completed;

		instructions instr_de_in;
		reg [31:0] rs1_val;
		reg [31:0] rs2_val;

		instructions instr_em_out;
		reg [31:0] rs1_em_out;
		reg [31:0] rs2_em_out;
		wire [31:0] rd_em_out;

		execute _execute
			( .clk(clk),
				.rstn(rstn & execute_rstn),

				.enabled(execute_enabled),
				.instr(instr_de_in),
				.rs1(rs1_val),
				.rs2(rs2_val),
				// .frs1,
				// .frs2,

				.completed(execute_completed),
				.instr_out(instr_em_out),
				.rs1_out(rs1_em_out),
				.rs2_out(rs2_em_out),
				// .frs1_out,
				// .frs2_out,

				.rd(rd_em_out) );


		// write
		reg  write_enabled;
		reg  write_rstn;
		// wire write_completed;
		reg write_completed;

		// assign register_out = state;
		task init;
			begin
				pc <= 32'b0;
				state <= 2'b00;

				fetch_enabled <= 1;
				decode_enabled <= 0;
				execute_enabled <= 0;
				write_enabled <= 0;

				fetch_rstn <= 1;
				decode_rstn <= 0;
				execute_rstn <= 0;
				write_rstn <= 0;

				register[2] <= 32'b10;
				register[3] <= 32'b1;
				// fetch_completed <= 1;
				// pc_fd_in <= 0;
				// instr_fd_in <= inst_mem[0];
 			end
		endtask

		task set_fd_reg;
			begin
				pc_fd_in <= pc;
				instr_fd_in <= inst_mem[pc];
				// register_out <= inst_mem[pc];
			end
		endtask

		task set_de_reg;
			begin
				instr_de_in <= instr_de_out;
				rs1_val <= register[rs1_num];
				rs2_val <= register[rs2_num];
			end
		endtask

		// task set_em_reg;
		// 	begin
		// 		instr_em_in <= instr_em_out;
		// 	end
		// endtask

		initial begin
      init();
		end

		always @(posedge clk) begin
			pc_out <= pc;
			state_out <= state;
			register_out <= register;
			if (rstn) begin
				if (state == 2'b00) begin
					fetch_completed <= 1;
					if (fetch_completed) begin
						state <= 2'b01;

						fetch_enabled <= 0;
						decode_enabled <= 1;
						execute_enabled <= 0;
						write_enabled <= 0;

						fetch_rstn <= 0;
						decode_rstn <= 1;
						execute_rstn <= 0;
						write_rstn <= 0;

						set_fd_reg();
					end
				end else if (state == 2'b01) begin
					if (decode_enabled == 1) begin
						decode_enabled <= 0;
					end

					if (decode_completed) begin
						state <= 2'b10;

						fetch_enabled <= 0;
						decode_enabled <= 0;
						execute_enabled <= 1;
						write_enabled <= 0;

						fetch_rstn <= 0;
						decode_rstn <= 0;
						execute_rstn <= 1;
						write_rstn <= 0;

						set_de_reg();
					end
				end else if (state == 2'b10) begin
					if (execute_enabled == 1) begin
						execute_enabled <= 0;
					end

					if (execute_completed) begin
						state <= 2'b11;

						fetch_enabled <= 0;
						decode_enabled <= 0;
						execute_enabled <= 0;
						write_enabled <= 1;

						fetch_rstn <= 0;
						decode_rstn <= 0;
						execute_rstn <= 0;
						write_rstn <= 1;

						// set_em_reg();
						register[instr_em_out.rd] <= rd_em_out;
						// register_out <= rd_em_out;
						write_completed <= 1;
					end
				end else if (state == 2'b11) begin
					if (write_completed) begin
						state <= 2'b00;

						fetch_enabled <= 1;
						decode_enabled <= 0;
						execute_enabled <= 0;
						write_enabled <= 0;

						fetch_rstn <= 1;
						decode_rstn <= 0;
						execute_rstn <= 0;
						write_rstn <= 0;

						pc <= pc + 1;
					end
				end
			end else begin
				init();
			end
		end


endmodule

`default_nettype wire