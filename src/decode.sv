`default_nettype none
`include "def.sv"

module decode
  ( input  wire         clk,
    input  wire         rstn,
    input  wire [31:0]  pc,
    input  wire         enabled,
    input  wire [31:0]  instr_raw,

    output wire         completed,
    output instructions instr,
    output wire [4:0]   rs1,
    output wire [4:0]   rs2 );


    wire [6:0]  funct7 = instr_raw[31:25];
    wire [4:0]  _rs2   = instr_raw[24:20];
    wire [4:0]  _rs1   = instr_raw[19:15];
    wire [2:0]  funct3 = instr_raw[14:12];
    wire [4:0]  _rd    = instr_raw[11:7];
    wire [6:0]  opcode = instr_raw[6:0];


    wire        r_type = (opcode == 7'b0110011 | opcode == 7'b1010011);
    wire        i_type = (opcode == 7'b1100111 | opcode == 7'b0000011 | opcode == 7'b0010011 | opcode == 7'b0000111);
    wire        s_type = (opcode == 7'b0100011 | opcode == 7'b0100111);
    wire        b_type = (opcode == 7'b1100011);
    wire        u_type = (opcode == 7'b0110111 | opcode == 7'b0010111);
    wire        j_type = (opcode == 7'b1101111);


    // j and u do not require rs1
    assign rs1 = (r_type || i_type || s_type || b_type) ? _rs1 : 5'b00000;
    // j, u, and i do not require rs2
    assign rs2 = (r_type || s_type || b_type) ? _rs2 : 5'b00000;

    wire        _addi  = (opcode == 7'b0110011);

		reg         _completed;
		assign completed = _completed & !enabled;

    always @(posedge clk) begin
      if (rstn) begin
				if (enabled) begin
					_completed <= 1;

					instr.addi <= _addi;

					instr.rd <= (r_type || i_type || u_type || j_type) ? _rd : 5'b00000;
					instr.rs1 <= (r_type || i_type || s_type || b_type) ? _rs1 : 5'b00000;
					instr.rs2 <= (r_type || s_type || b_type) ? _rs2 : 5'b00000;

					instr.pc <= pc;
				end
			end else begin
				_completed <= 0;
			end
    end

endmodule

`default_nettype wire