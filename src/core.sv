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

		// branch prediction
		wire [6:0] opcode = instr_fd_out[6:0];
		wire _jal         = (opcode == 7'b1101111);
		wire _jalr        = (opcode == 7'b1100111);
		wire _cond_jump   = (opcode == 7'b1100011);
		wire is_jump_f    = (_jal || _jalr || _cond_jump);

		reg [2:0]  bht  [255:0];
		reg [55:0] btac [255:0];

		wire [31:0] pred_jump_dest = (bht[pc[7:0]][2:1] == 2'b11 && btac[pc[7:0]][55:32] == pc[31:8]) ?
																	btac[pc[7:0]][31:0] : pc + 1;

		wire is_jump_e = (execute_rstn == 1 && (instr_de.jal || instr_de.jalr || instr_de.is_conditional_jump));
		wire pred_succeed = (is_jump_e == 1 && jump_dest == pc_fd_in);
		wire pred_fail = (is_jump_e == 1 && jump_dest != pc_fd_in);
		wire [31:0] pc_e = instr_de.pc;
		wire [1:0]  t_bh = (bht[pc_e[7:0]][1:0] == 2'b00) ? 2'b01 :
									 		 (bht[pc_e[7:0]][1:0] == 2'b01) ? 2'b10 :
									 		 2'b11;
		wire [1:0] nt_bh = (bht[pc_e[7:0]][1:0] == 2'b11) ? 2'b10 :
											 (bht[pc_e[7:0]][1:0] == 2'b10) ? 2'b01 :
											 2'b00;
		wire f_bh = (bht[pc_e[7:0]][2] || (is_jump_e && !pred_succeed));

		integer i;
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

				for (i=0; i<256; i++) begin
						bht[i]  <= 3'b0;
						btac[i] <= 56'b0;
				end
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

				rs1_de_in <= (execute_rstn == 1 && rs1_addr == instr_de.rd) ? rd_ew_out :
										//  (rs1_addr == instr_ew.rd) ? rd_ew_in  :
										 rs1_data;
				rs2_de_in <= (execute_rstn == 1 && rs2_addr == instr_de.rd) ? rd_ew_out :
										//  (rs2_addr == instr_ew.rd) ? rd_ew_in  :
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

				if (pred_fail) begin
					bht[pc_e[7:0]] <= {f_bh, nt_bh};
					if (is_jump) begin
						btac[pc_e[7:0]] <= {pc_e[31:8], jump_dest};
					end

					pc <= jump_dest;

					fetch_enabled <= 1;
					decode_enabled <= 0;
					execute_enabled <= 0;
					write_enabled <= execute_enabled;

					fetch_rstn <= 1;
					decode_rstn <= 0;
					execute_rstn <= 0;
					write_rstn <= execute_rstn;
				end else begin
					if (pred_succeed) begin
						bht[pc[7:0]] <= {f_bh, t_bh};
					end

					pc <= (is_jump_f) ? pred_jump_dest : pc + 1;

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
			end else begin
				init();
			end
		end
endmodule

`default_nettype wire