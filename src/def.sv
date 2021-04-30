
`ifndef _parameters_state_
 `define _parameters_state_

typedef struct {
    // metadata
    wire [4:0]  rd;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [31:0] imm;
    wire [31:0] pc;

    // rv32i
    wire        lui;
    wire        auipc;

    wire        jal;
    wire        jalr;

    wire        beq;
    wire        bne;
    wire        blt;
    wire        bge;
    wire        bltu;
    wire        bgeu;

    wire        lb;
    wire        lh;
    wire        lw;
    wire        lbu;
    wire        lhu;
    wire        sb;
    wire        sh;
    wire        sw;

    wire        addi;
    wire        slti;
    wire        sltiu;
    wire        xori;
    wire        ori;
    wire        andi;
    wire        slli;
    wire        srli;
    wire        srai;

    wire        add;
    wire        sub;
    wire        sll;
    wire        slt;
    wire        sltu;
    wire        xor;
    wire        sra;
    wire        or;
    wire        and;

    wire        fence;
    wire        fencei;
    wire        ecall;
    wire        ebreak;
    wire        csrrw;
    wire        csrrs;
    wire        csrrc;
    wire        csrrwi;
    wire        csrrsi;
    wire        csrrci;

    // rv32m
    wire        mul;
    wire        mulh;
    wire        mulhsu;
    wire        div;
    wire        divu;
    wire        rem;
    wire        remu;

    // control flags
    wire        is_store;
    wire        is_load;
    wire        is_conditional_jump;
} instuctions;

`endif