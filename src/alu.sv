`default_nettype none
`include "def.sv"

module alu
  ( input  wire         clk,
    input  wire         rstn,

    input  wire         enabled,
    input  instructions instr,
    input  reg  [31:0]  rs1,
    input  reg  [31:0]  rs2,
    input  reg  [31:0]  csr,

    output reg          completed,

    output wire [31:0]  rd );

  wire [31:0] _rs1_pn = rs1[31] ? ~32'b0 : 32'b0;
  wire [31:0] _rs2_pn = rs2[31] ? ~32'b0 : 32'b0;
  wire [63:0] _mulss = $signed({_rs1_pn, rs1} * $signed({_rs2_pn, rs2}));
  wire [63:0] _mulsu = $signed({_rs1_pn, rs1} * $signed({  32'b0, rs2}));
  wire [63:0] _muluu = $signed({  32'b0, rs1} * $signed({  32'b0, rs2}));

  assign rd = enabled ?
     (instr.lui    ? instr.imm :
      instr.auipc  ? $signed(instr.pc) + $signed(instr.imm) :

      instr.jal    ? instr.pc + 1 :
      instr.jalr   ? instr.pc + 1 :

      instr.beq    ? rs1 == rs2 :
      instr.bne    ? rs1 != rs1 :
      instr.blt    ? $signed(rs1) < $signed(rs2) :
      instr.bge    ? $signed(rs1) >= $signed(rs2) :
      instr.bltu   ? rs1 < rs2:
      instr.bgeu   ? rs1 >= rs2:

      // もしかしたら rs1 は >>> 2 しない方がいいかも
      // instr.lb     ? :
      // instr.lh     ? :
      // instr.lw     ? $signed(($signed(rs1) + $signed(instr.imm))) >>> 2:
      // instr.lbu    ? :
      // instr.lhu    ? :

      // instr.sb     ? :
      // instr.sh     ? :
      // instr.sw     ? $signed(($signed(rs1) + $signed(instr.imm))) >>> 2:

      instr.addi   ? $signed(rs1) + $signed(instr.imm) :
      instr.slti   ? $signed(rs1) < $signed(instr.imm) :
      instr.sltiu  ? rs1 < instr.imm :
      instr.xori   ? rs1 ^ instr.imm :
      instr.ori    ? rs1 | instr.imm :
      instr.andi   ? rs1 & instr.imm :
      instr.slli   ? rs1 << instr.imm[4:0] :
      instr.srli   ? rs1 >> instr.imm[4:0] :
      instr.srai   ? $signed(rs1) >>> instr.imm[4:0] :

      instr.add    ? $signed(rs1) + $signed(rs2) :
      instr.sub    ? $signed(rs1) - $signed(rs2) :
      instr.sll    ? $signed(rs1) << $signed(rs2) :
      instr.slt    ? $signed(rs1) < $signed(rs2) :
      instr.sltu   ? rs1 < rs2 :
      instr.i_xor  ? rs1 ^ rs2 :
      instr.srl    ? rs1 >> rs2 :
      instr.sra    ? $signed(rs1) >>> rs2 :
      instr.i_or   ? rs1 | rs2 :
      instr.i_and  ? rs1 & rs2 :

      // instr.fence  ? :
      // instr.fencei ? :
      // instr.ecall  ? :
      // instr.ebreak ? :
      instr.csrrw  ? rs1 :
      instr.csrrs  ? csr | rs1 :
      instr.csrrc  ? csr & ~rs1 :
      instr.csrrwi ? {27'b0, instr.rs1} :
      instr.csrrsi ? csr | {27'b0, instr.rs1} :
      instr.csrrci ? csr & ~{27'b0, instr.rs1} :

      instr.mul    ? _mulss[31:0] :
      instr.mulh   ? _mulss[63:32] :
      instr.mulhsu ? _mulsu[63:32] :
      instr.mulhu  ? _muluu[63:32] :
      instr.div    ? $signed(rs1) / $signed(rs2) :
      instr.divu   ? rs1 / rs2 :
      instr.rem    ? $signed(rs1) % $signed(rs2):
      instr.remu   ? rs1 % rs2 :
      32'b0) : 32'b0;

endmodule

`default_nettype wire
