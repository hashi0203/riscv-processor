`default_nettype none
`include "def.sv"

module core
	( input wire      clk,
		input wire      rstn,

		output reg [31:0] pc_out,
		output reg [1:0]  state_out,
		output reg [31:0] rd_out,
		output reg [31:0] regs_out [31:0] );

		reg [31:0] pc;
		reg [1:0]  state;
		reg        is_stall;

		// fetch
		reg  fetch_enabled;
		reg  fetch_rstn;
		wire fetch_completed;

		wire [31:0] pc_fd_out;
		wire [31:0] instr_fd_out;

		fetch _fetch
			( .clk(clk),
				.rstn(rstn & fetch_rstn),
				.enabled(fetch_enabled),
				.pc(pc),

				.completed(fetch_completed),
				.pc_n(pc_fd_out),
				.instr_raw(instr_fd_out) );

		// decode
		reg  decode_enabled;
		reg  decode_rstn;
		wire decode_completed;

		reg [31:0] pc_fd_in;
		reg [31:0] instr_fd_in;

		instructions instr_de;
		wire [4:0] rs1_addr;
		wire [4:0] rs2_addr;
		wire       may_jump;

		decode _decode
			( .clk(clk),
				.rstn(rstn & decode_rstn),
				.pc(pc_fd_in),
				.enabled(decode_enabled),
				.instr_raw(instr_fd_in),

				.completed(decode_completed),
				.instr(instr_de),
				.rs1(rs1_addr),
				.rs2(rs2_addr),
				.may_jump(may_jump) );

		// execute
		reg  execute_enabled;
		reg  execute_rstn;
		wire execute_completed;

		// instructions instr_de_in;
		reg [31:0] rs1_de_in;
		reg [31:0] rs2_de_in;

		instructions instr_ew;
		// reg  [31:0] rs1_ew_out;
		// reg  [31:0] rs2_ew_out;
		wire [31:0] rd_ew_out;
		wire        is_jump;
		wire [31:0] jump_dest;

		execute _execute
			( .clk(clk),
				.rstn(rstn & execute_rstn),

				.enabled(execute_enabled),
				.instr(instr_de),
				.rs1(rs1_de_in),
				.rs2(rs2_de_in),

				.completed(execute_completed),
				.instr_out(instr_ew),
				// .rs1_out(rs1_ew_out),
				// .rs2_out(rs2_ew_out),

				.rd(rd_ew_out),
				.is_jump(is_jump),
				.jump_dest(jump_dest) );


		// write
		reg  write_enabled;
		reg  write_rstn;
		wire write_completed;

		// instructions instr_ew_in;
		reg [31:0]  rd_ew_in;

		wire        reg_w_enabled;
		wire [4:0]  reg_w_addr;
		wire [31:0] reg_w_data;

		write _write
			( .clk(clk),
				.rstn(rstn & write_rstn),
				.enabled(write_enabled),
				.instr(instr_ew),
				.data(rd_ew_in),

				.reg_w_enabled(reg_w_enabled),
				.reg_w_addr(reg_w_addr),
				.reg_w_data(reg_w_data),
				.completed(write_completed) );

		wire [31:0] rs1_data;
		wire [31:0] rs2_data;
		reg  [31:0] regs [31:0];

		register _register
			( .clk(clk),
				.rstn(rstn),
				.r_enabled(decode_enabled),

   			.rs1_addr(rs1_addr),
   			.rs2_addr(rs2_addr),

  			.rs1_data(rs1_data),
   			.rs2_data(rs2_data),

   			.w_enabled(reg_w_enabled),
   			.w_addr(reg_w_addr),
   			.w_data(reg_w_data),

	 			.regs_out(regs) );

		task init;
			begin
				pc <= 32'b0;
				state <= 2'b00;
				is_stall <= 0;

				fetch_enabled <= 1;
				decode_enabled <= 0;
				execute_enabled <= 0;
				write_enabled <= 0;

				fetch_rstn <= 1;
				decode_rstn <= 0;
				execute_rstn <= 0;
				write_rstn <= 0;
 			end
		endtask

		task set_fd_reg;
			begin
				pc_fd_in <= pc;
				instr_fd_in <= instr_fd_out;
			end
		endtask

		task set_de_reg;
			begin
				// instr_de_in <= instr_de_out;
				// rs1_de_in <= rs1_data;
				// rs2_de_in <= rs2_data;

				rs1_de_in <= (rs1_addr == instr_de.rd) ? rd_ew_out :
										 (rs1_addr == instr_ew.rd) ? rd_ew_in  :
										 rs1_data;
				rs2_de_in <= (rs2_addr == instr_de.rd) ? rd_ew_out :
										 (rs2_addr == instr_ew.rd) ? rd_ew_in  :
										 rs2_data;
			end
		endtask

		task set_ew_reg;
			begin
				// instr_ew_in <= instr_ew_out;
				rd_ew_in <= rd_ew_out;
			end
		endtask

		initial begin
      init();
		end

		always @(posedge clk) begin
			pc_out <= pc;
			state_out <= state;
			rd_out <= rd_ew_out;
			regs_out <= regs;
			if (rstn) begin

				if (is_stall) begin
					pc <= jump_dest;
					is_stall <= 0;

					fetch_enabled <= 1;
					decode_enabled <= fetch_enabled;
					execute_enabled <= decode_enabled;
					write_enabled <= execute_enabled;

					fetch_rstn <= 1;
					decode_rstn <= fetch_rstn;
					execute_rstn <= decode_rstn;
					write_rstn <= execute_rstn;
				end else if (may_jump) begin
					is_stall <= 1;

					fetch_enabled <= 0;
					decode_enabled <= 0;
					execute_enabled <= decode_enabled;
					write_enabled <= execute_enabled;

					fetch_rstn <= 0;
					decode_rstn <= 0;
					execute_rstn <= decode_rstn;
					write_rstn <= execute_rstn;
				end else begin
					pc <= pc + 1;

					decode_enabled <= fetch_enabled;
					execute_enabled <= decode_enabled;
					write_enabled <= execute_enabled;

					decode_rstn <= fetch_rstn;
					execute_rstn <= decode_rstn;
					write_rstn <= execute_rstn;
				end

				set_fd_reg();
				set_de_reg();
				set_ew_reg();


				// state <= 2'b01;

				// 	fetch_enabled <= 0;
				// 	decode_enabled <= 1;
				// 	execute_enabled <= 0;
				// 	write_enabled <= 0;

				// 	fetch_rstn <= 0;
				// 	decode_rstn <= 1;
				// 	execute_rstn <= 0;
				// 	write_rstn <= 0;

				// 	set_fd_reg();
				// end else if (state == 2'b01) begin
				// 	state <= 2'b10;

				// 	fetch_enabled <= 0;
				// 	decode_enabled <= 0;
				// 	execute_enabled <= 1;
				// 	write_enabled <= 0;

				// 	fetch_rstn <= 0;
				// 	decode_rstn <= 0;
				// 	execute_rstn <= 1;
				// 	write_rstn <= 0;

				// 	set_de_reg();
				// end else if (state == 2'b10) begin
				// 	state <= 2'b11;

				// 	fetch_enabled <= 0;
				// 	decode_enabled <= 0;
				// 	execute_enabled <= 0;
				// 	write_enabled <= 1;

				// 	fetch_rstn <= 0;
				// 	decode_rstn <= 0;
				// 	execute_rstn <= 0;
				// 	write_rstn <= 1;

				// 	set_ew_reg();

				// 	pc <= jump_dest;
				// end else if (state == 2'b11) begin
				// 	state <= 2'b00;

				// 	fetch_enabled <= 1;
				// 	decode_enabled <= 0;
				// 	execute_enabled <= 0;
				// 	write_enabled <= 0;

				// 	fetch_rstn <= 1;
				// 	decode_rstn <= 0;
				// 	execute_rstn <= 0;
				// 	write_rstn <= 0;

				// if (state == 2'b00) begin
				// 	state <= 2'b01;

				// 	fetch_enabled <= 0;
				// 	decode_enabled <= 1;
				// 	execute_enabled <= 0;
				// 	write_enabled <= 0;

				// 	fetch_rstn <= 0;
				// 	decode_rstn <= 1;
				// 	execute_rstn <= 0;
				// 	write_rstn <= 0;

				// 	set_fd_reg();
				// end else if (state == 2'b01) begin
				// 	state <= 2'b10;

				// 	fetch_enabled <= 0;
				// 	decode_enabled <= 0;
				// 	execute_enabled <= 1;
				// 	write_enabled <= 0;

				// 	fetch_rstn <= 0;
				// 	decode_rstn <= 0;
				// 	execute_rstn <= 1;
				// 	write_rstn <= 0;

				// 	set_de_reg();
				// end else if (state == 2'b10) begin
				// 	state <= 2'b11;

				// 	fetch_enabled <= 0;
				// 	decode_enabled <= 0;
				// 	execute_enabled <= 0;
				// 	write_enabled <= 1;

				// 	fetch_rstn <= 0;
				// 	decode_rstn <= 0;
				// 	execute_rstn <= 0;
				// 	write_rstn <= 1;

				// 	set_ew_reg();

				// 	pc <= jump_dest;
				// end else if (state == 2'b11) begin
				// 	state <= 2'b00;

				// 	fetch_enabled <= 1;
				// 	decode_enabled <= 0;
				// 	execute_enabled <= 0;
				// 	write_enabled <= 0;

				// 	fetch_rstn <= 1;
				// 	decode_rstn <= 0;
				// 	execute_rstn <= 0;
				// 	write_rstn <= 0;
				// end
			end else begin
				init();
			end
		end
endmodule

`default_nettype wire