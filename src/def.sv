
`ifndef _parameters_state_
 `define _parameters_state_

typedef struct {
  // metadata
  reg [4:0]  rd;
  reg [4:0]  rs1;
  reg [4:0]  rs2;
  reg [31:0] imm;
  reg [31:0] pc;
  reg [31:0] raw;

  // rv32i
  reg        lui;
  reg        auipc;

  reg        jal;
  reg        jalr;

  reg        beq;
  reg        bne;
  reg        blt;
  reg        bge;
  reg        bltu;
  reg        bgeu;

  reg        lb;
  reg        lh;
  reg        lw;
  reg        lbu;
  reg        lhu;
  reg        sb;
  reg        sh;
  reg        sw;

  reg        addi;
  reg        slti;
  reg        sltiu;
  reg        xori;
  reg        ori;
  reg        andi;
  reg        slli;
  reg        srli;
  reg        srai;

  reg        add;
  reg        sub;
  reg        sll;
  reg        slt;
  reg        sltu;
  reg        i_xor;
  reg        srl;
  reg        sra;
  reg        i_or;
  reg        i_and;

  reg        fence;
  reg        fencei;
  reg        ecall;
  reg        ebreak;
  reg        csrrw;
  reg        csrrs;
  reg        csrrc;
  reg        csrrwi;
  reg        csrrsi;
  reg        csrrci;

  // rv32m
  reg        mul;
  reg        mulh;
  reg        mulhsu;
  reg        mulhu;
  reg        div;
  reg        divu;
  reg        rem;
  reg        remu;

  // privileged instructions
  reg        mret;

  // control flags
  reg        is_store;
  reg        is_load;
  reg        is_conditional_jump;
  reg        is_illegal_instr;
} instructions;

`endif