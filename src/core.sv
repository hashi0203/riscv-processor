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

		// fib
		reg [31:0] inst_mem [0:35] = '{
			32'b00000111010000000000000011101111,  //  0. jal	ra,74 <main>
			32'b11111110000000010000000100010011,  //  1. addi	sp(=r2),sp,-32
			32'b00000000000100010010111000100011,  //  2. sw	ra(=r1),28(sp)
			32'b00000000100000010010110000100011,  //  3. sw	s0(=r8),24(sp)
			32'b00000000100100010010101000100011,  //  4. sw	s1(=r9),20(sp)
			32'b00000010000000010000010000010011,  //  5. addi	s0,sp,32
			32'b11111110101001000010011000100011,  //  6. sw	a0(=r10),-20(s0)
			32'b11111110110001000010011100000011,  //  7. lw	a4(=r14),-20(s0)
			32'b00000000000100000000011110010011,  //  8. li	a5(=r15),1
			32'b00000000111001111100011001100011,  //  9. blt	a5,a4,30 <fib+0x2c>
			32'b00000000000100000000011110010011,  // 10. li	a5,1
			32'b00000011000000000000000001101111,  // 11. j	5c <fib+0x58>
			32'b11111110110001000010011110000011,  // 12. lw	a5,-20(s0)
			32'b11111111111101111000011110010011,  // 13. addi	a5,a5,-1
			32'b00000000000001111000010100010011,  // 14. mv	a0,a5
			32'b11111100100111111111000011101111,  // 15. jal	ra,4 <fib>
			32'b00000000000001010000010010010011,  // 16. mv	s1,a0
			32'b11111110110001000010011110000011,  // 17. lw	a5,-20(s0)
			32'b11111111111001111000011110010011,  // 18. addi	a5,a5,-2
			32'b00000000000001111000010100010011,  // 19. mv	a0,a5
			32'b11111011010111111111000011101111,  // 20. jal	ra,4 <fib>
			32'b00000000000001010000011110010011,  // 21. mv	a5,a0
			32'b00000000111101001000011110110011,  // 22. add	a5,s1,a5
			32'b00000000000001111000010100010011,  // 23. mv	a0,a5
			32'b00000001110000010010000010000011,  // 24. lw	ra,28(sp)
			32'b00000001100000010010010000000011,  // 25. lw	s0,24(sp)
			32'b00000001010000010010010010000011,  // 26. lw	s1,20(sp)
			32'b00000010000000010000000100010011,  // 27. addi	sp,sp,32
			32'b00000000000000001000000001100111,  // 28. ret
			32'b11111111000000010000000100010011,  // 29. addi	sp,sp,-16
			32'b00000000000100010010011000100011,  // 30. sw	ra,12(sp)
			32'b00000000100000010010010000100011,  // 31. sw	s0,8(sp)
			32'b00000001000000010000010000010011,  // 32. addi	s0,sp,16
			32'b00000000101000000000010100010011,  // 33. li	a0,10
			32'b11110111110111111111000011101111,  // 34. jal	ra,4 <fib>
			32'b00000000000000000000000001101111   // 35. j	8c <main+0x18>
		};

		// memory
		// reg [31:0] inst_mem [0:16] = '{
		// 	32'b00000000010000000000000011101111,  //  0. jal	ra,4 <main> r1 を 1 に書き換える
		// 	32'b11111110000000010000000100010011,  //  1. addi	sp(=r2),sp,-32
		// 	32'b00000000100000010010111000100011,  //  2. sw	s0(=r8),28(sp)(=28)
		// 	32'b00000010000000010000010000010011,  //  3. addi	s0,sp,32
		// 	32'b00000000000100000000011110010011,  //  4. li	a5(=r15),1
		// 	32'b11111110111101000010001000100011,  //  5. sw	a5,-28(s0)(=4)
		// 	32'b00000000001000000000011110010011,  //  6. li	a5,2 = addi a5 r0 2
		// 	32'b11111110111101000010010000100011,  //  7. sw	a5,-24(s0)(=8)
		// 	32'b11111110010001000010011100000011,  //  8. lw	a4(=r14),-28(s0)(=4)
		// 	32'b11111110100001000010011110000011,  //  9. lw	a5,-24(s0)(=8)
		// 	32'b00000000111101110000011110110011,  // 10. add	a5,a4,a5
		// 	32'b11111110111101000010011000100011,  // 11. sw	a5,-20(s0)(=12)
		// 	32'b00000000000000000000011110010011,  // 12. li	a5,0
		// 	32'b00000000000001111000010100010011,  // 13. mv	a0(=r10),a5 = addi a0 a5 0
		// 	32'b00000001110000010010010000000011,  // 14. lw	s0,28(sp)(=28)
		// 	32'b00000010000000010000000100010011,  // 15. addi	sp,sp,32
		// 	32'b00000000000000001000000001100111   // 16. ret = jalr r1 0 (r1+0のアドレスにジャンプ)
		// };

		// add + jump
		// reg [31:0] inst_mem [0:9] = '{
		// 	32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
		// 	32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
		// 	32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
		// 	32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
		// 	32'b00000000001000011000000110110011, // ADD 3(rs1) + 2(rs2) = 3(rd)
		// 	32'b00000000001000011000000110110011,  // ADD 3(rs1) + 2(rs2) = 3(rd)
		// 	32'b00000000001000011000000110110011,  // ADD 3(rs1) + 2(rs2) = 3(rd)
		// 	32'b00000000010000011101001001100011,  // BGE 3(rs1) >= 4(rs2) -> 2(imm)
		// 	32'b00000000001000011000001010110011,  // ADD 3(rs1) + 2(rs2) = 5(rd)
		// 	32'b11111111110111111111000011101111   // JAL -2(imm) 1(rd)
		// };

		reg [31:0] mem [0:1023];

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
		reg  [31:0] rs1_em_out;
		reg  [31:0] rs2_em_out;
		wire [31:0] rd_em_out;
		wire        is_jump;
		wire [31:0] jump_dest;

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

				.rd(rd_em_out),
				.is_jump(is_jump),
				.jump_dest(jump_dest) );


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

				register[0] <= 32'b0;
				register[1] <= 32'b0;
				// register[2] <= 32'b10;
				// register[2] <= 32'b100000;
				register[2] <= 32'd512;
				// register[3] <= 32'b1;
				register[3] <= 32'b0;
				register[4] <= 32'b0;
				register[5] <= 32'b0;
				register[6] <= 32'b0;
				register[7] <= 32'b0;
				register[8] <= 32'b0;
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
						if (instr_em_out.lw) begin
							register[instr_em_out.rd] <= mem[rd_em_out];
						end else if (instr_em_out.sw) begin
							mem[rd_em_out] <= rs2_em_out;
						end else if (instr_em_out.rd != 32'b0) begin
							register[instr_em_out.rd] <= rd_em_out;
						end
						// register_out <= rd_em_out;
						write_completed <= 1;

						pc <= jump_dest;
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

						// pc <= pc + 1;
					end
				end
			end else begin
				init();
			end
		end


endmodule

`default_nettype wire