`default_nettype none
`include "def.sv"

module execute #(parameter MEM_SIZE = 32'd1024)
  ( input  wire         clk,
    input  wire         rstn,

    input  wire         enabled,
    input  instructions instr,
    input  reg [31:0]   rs1_data,
    input  reg [31:0]   rs2_data,
    input  reg [31:0]   csr_data,

    output instructions instr_out,
    output wire [31:0]  rd_data,
    output wire [31:0]  csrd_data,
    output wire         is_jump,
    output wire [31:0]  jump_dest );

  wire [31:0] alu_rd_data;
  alu _alu
    ( .clk(clk),
      .rstn(rstn),
      .enabled(enabled),
      .instr(instr),
      .rs1_data(rs1_data),
      .rs2_data(rs2_data),
      .csr_data(csr_data),
      .rd_data(alu_rd_data) );

  wire [31:0] r_data;
  memory #(.MEM_SIZE(MEM_SIZE)) _memory
    ( .clk(clk),
      .rstn(rstn),
      .base(rs1_data),
      .offset(instr.imm),

      .r_enabled(instr.is_load),
      .r_data(r_data),
      .w_enabled(instr.is_store),
      .w_data(rs2_data) );

  assign rd_data   = (rstn && enabled) ? (instr.is_load ? r_data :
                                          instr.is_csr ? csr_data :
                                          alu_rd_data) : 32'b0;
  assign csrd_data = (rstn && enabled) ? (instr.is_csr ? alu_rd_data : csr_data) : 32'b0;
  assign is_jump   = (rstn && enabled) && (instr.jal || instr.jalr || (instr.is_conditional_jump && alu_rd_data == 32'b1));
  assign jump_dest = (rstn && enabled) ?
                     (instr.jal  ? $signed(instr.pc) + $signed($signed(instr.imm) >>> 2) :
                      instr.jalr ? $signed(rs1_data) + $signed($signed(instr.imm) >>> 2) :
                      instr.is_conditional_jump && alu_rd_data == 32'b1 ? $signed(instr.pc) + $signed($signed(instr.imm) >>> 2) :
                      instr.pc + 1) : 32'b0;

  always @(posedge clk) begin
    if (rstn) begin
      if (enabled) begin
        instr_out <= instr;
      end
    end else begin
      instr_out <= '{ default:0 };
    end
  end
endmodule

`default_nettype wire
