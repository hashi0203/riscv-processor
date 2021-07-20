`default_nettype none
`include "def.sv"

module alu
  ( input  wire         clk,
    input  wire         rstn,

    input  wire         enabled,
    input  instructions instr,
    input  reg  [31:0]  rs1_data,
    input  reg  [31:0]  rs2_data,
    input  reg  [31:0]  csr_data,

    output wire [31:0]  rd_data );

  wire [31:0] _rs1_pn = rs1_data[31] ? ~32'b0 : 32'b0;
  wire [31:0] _rs2_pn = rs2_data[31] ? ~32'b0 : 32'b0;
  wire [63:0] _mulss = $signed({_rs1_pn, rs1_data} * $signed({_rs2_pn, rs2_data}));
  wire [63:0] _mulsu = $signed({_rs1_pn, rs1_data} * $signed({  32'b0, rs2_data}));
  wire [63:0] _muluu = $signed({  32'b0, rs1_data} * $signed({  32'b0, rs2_data}));

  assign rd_data = (rstn && enabled) ?
     (instr.lui    ? instr.imm :
      instr.auipc  ? $signed(instr.pc) + $signed(instr.imm) :

      instr.jal    ? instr.pc + 1 :
      instr.jalr   ? instr.pc + 1 :

      instr.beq    ? rs1_data == rs2_data :
      instr.bne    ? rs1_data != rs1_data :
      instr.blt    ? $signed(rs1_data) < $signed(rs2_data) :
      instr.bge    ? $signed(rs1_data) >= $signed(rs2_data) :
      instr.bltu   ? rs1_data < rs2_data:
      instr.bgeu   ? rs1_data >= rs2_data:

      // instr.lb     ? :
      // instr.lh     ? :
      // instr.lw     ? $signed(($signed(rs1_data) + $signed(instr.imm))) >>> 2:
      // instr.lbu    ? :
      // instr.lhu    ? :

      // instr.sb     ? :
      // instr.sh     ? :
      // instr.sw     ? $signed(($signed(rs1_data) + $signed(instr.imm))) >>> 2:

      instr.addi   ? $signed(rs1_data) + $signed(instr.imm) :
      instr.slti   ? $signed(rs1_data) < $signed(instr.imm) :
      instr.sltiu  ? rs1_data < instr.imm :
      instr.xori   ? rs1_data ^ instr.imm :
      instr.ori    ? rs1_data | instr.imm :
      instr.andi   ? rs1_data & instr.imm :
      instr.slli   ? rs1_data << instr.imm[4:0] :
      instr.srli   ? rs1_data >> instr.imm[4:0] :
      instr.srai   ? $signed(rs1_data) >>> instr.imm[4:0] :

      instr.add    ? $signed(rs1_data) + $signed(rs2_data) :
      instr.sub    ? $signed(rs1_data) - $signed(rs2_data) :
      instr.sll    ? $signed(rs1_data) << $signed(rs2_data) :
      instr.slt    ? $signed(rs1_data) < $signed(rs2_data) :
      instr.sltu   ? rs1_data < rs2_data :
      instr.i_xor  ? rs1_data ^ rs2_data :
      instr.srl    ? rs1_data >> rs2_data :
      instr.sra    ? $signed(rs1_data) >>> rs2_data :
      instr.i_or   ? rs1_data | rs2_data :
      instr.i_and  ? rs1_data & rs2_data :

      // instr.fence  ? :
      // instr.fencei ? :
      // instr.ecall  ? :
      // instr.ebreak ? :
      instr.csrrw  ? rs1_data :
      instr.csrrs  ? csr_data | rs1_data :
      instr.csrrc  ? csr_data & ~rs1_data :
      instr.csrrwi ? instr.zimm :
      instr.csrrsi ? csr_data | instr.zimm :
      instr.csrrci ? csr_data & ~instr.zimm :

      instr.mul    ? _mulss[31:0] :
      instr.mulh   ? _mulss[63:32] :
      instr.mulhsu ? _mulsu[63:32] :
      instr.mulhu  ? _muluu[63:32] :
      instr.div    ? $signed(rs1_data) / $signed(rs2_data) :
      instr.divu   ? rs1_data / rs2_data :
      instr.rem    ? $signed(rs1_data) % $signed(rs2_data):
      instr.remu   ? rs1_data % rs2_data :
      32'b0) : 32'b0;

endmodule

`default_nettype wire
