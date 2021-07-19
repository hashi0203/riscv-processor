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
    output wire [4:0]   rs2,
    output wire [11:0]  csr );


  wire [6:0] funct7   = instr_raw[31:25];
  wire [4:0] _rs2     = instr_raw[24:20];
  wire [4:0] _rs1     = instr_raw[19:15];
  wire [2:0] funct3   = instr_raw[14:12];
  wire [4:0] _rd      = instr_raw[11:7];
  wire [6:0] opcode   = instr_raw[6:0];

  wire _is_privileged = (opcode == 7'b1110011 && (funct3 == 3'b000 || funct3 == 3'b100));
  wire       _is_csr  = (opcode == 7'b1110011 && !_is_privileged);
  wire       r_type   = (opcode == 7'b0110011 || opcode == 7'b1010011 || _is_privileged);
  wire       i_type   = (opcode == 7'b1100111 || opcode == 7'b0000011 || opcode == 7'b0010011 || opcode == 7'b0000111 || _is_csr);
  wire       s_type   = (opcode == 7'b0100011 || opcode == 7'b0100111);
  wire       b_type   = (opcode == 7'b1100011);
  wire       u_type   = (opcode == 7'b0110111 || opcode == 7'b0010111);
  wire       j_type   = (opcode == 7'b1101111);

  wire      need_zimm = _is_csr && (funct3 == 3'b101 || funct3 == 3'b110 || funct3 == 3'b111);

  // j and u do not require rs1
  assign rs1 = enabled && (r_type || i_type || s_type || b_type) && !need_zimm ? _rs1 : 5'b00000;
  // j, u, and i do not require rs2
  assign rs2 = enabled && (r_type || s_type || b_type) ? _rs2 : 5'b00000;

  assign csr = _is_csr ? instr_raw[31:25] : 12'b0;

  wire _lui    = (opcode == 7'b0110111);
  wire _auipc  = (opcode == 7'b0010111);

  wire _jal    = (opcode == 7'b1101111);
  wire _jalr   = (opcode == 7'b1100111);

  wire _beq    = (opcode == 7'b1100011) && (funct3 == 3'b000);
  wire _bne    = (opcode == 7'b1100011) && (funct3 == 3'b001);
  wire _blt    = (opcode == 7'b1100011) && (funct3 == 3'b100);
  wire _bge    = (opcode == 7'b1100011) && (funct3 == 3'b101);
  wire _bltu   = (opcode == 7'b1100011) && (funct3 == 3'b110);
  wire _bgeu   = (opcode == 7'b1100011) && (funct3 == 3'b111);

  wire _lb     = (opcode == 7'b0000011) && (funct3 == 3'b000);
  wire _lh     = (opcode == 7'b0000011) && (funct3 == 3'b001);
  wire _lw     = (opcode == 7'b0000011) && (funct3 == 3'b010);
  wire _lbu    = (opcode == 7'b0000011) && (funct3 == 3'b100);
  wire _lhu    = (opcode == 7'b0000011) && (funct3 == 3'b101);

  wire _sb     = (opcode == 7'b0100011) && (funct3 == 3'b000);
  wire _sh     = (opcode == 7'b0100011) && (funct3 == 3'b001);
  wire _sw     = (opcode == 7'b0100011) && (funct3 == 3'b010);

  wire _addi   = (opcode == 7'b0010011) && (funct3 == 3'b000);
  wire _slti   = (opcode == 7'b0010011) && (funct3 == 3'b010);
  wire _sltiu  = (opcode == 7'b0010011) && (funct3 == 3'b011);
  wire _xori   = (opcode == 7'b0010011) && (funct3 == 3'b100);
  wire _ori    = (opcode == 7'b0010011) && (funct3 == 3'b110);
  wire _andi   = (opcode == 7'b0010011) && (funct3 == 3'b111);
  wire _slli   = (opcode == 7'b0010011) && (funct3 == 3'b001) && (funct7 == 7'b0000000);
  wire _srli   = (opcode == 7'b0010011) && (funct3 == 3'b101) && (funct7 == 7'b0000000);
  wire _srai   = (opcode == 7'b0010011) && (funct3 == 3'b101) && (funct7 == 7'b0100000);

  wire _add    = (opcode == 7'b0110011) && (funct3 == 3'b000) && (funct7 == 7'b0000000);
  wire _sub    = (opcode == 7'b0110011) && (funct3 == 3'b000) && (funct7 == 7'b0100000);
  wire _sll    = (opcode == 7'b0110011) && (funct3 == 3'b001) && (funct7 == 7'b0000000);
  wire _slt    = (opcode == 7'b0110011) && (funct3 == 3'b010) && (funct7 == 7'b0000000);
  wire _sltu   = (opcode == 7'b0110011) && (funct3 == 3'b011) && (funct7 == 7'b0000000);
  wire _i_xor  = (opcode == 7'b0110011) && (funct3 == 3'b100) && (funct7 == 7'b0000000);
  wire _srl    = (opcode == 7'b0110011) && (funct3 == 3'b101) && (funct7 == 7'b0000000);
  wire _sra    = (opcode == 7'b0110011) && (funct3 == 3'b101) && (funct7 == 7'b0100000);
  wire _i_or   = (opcode == 7'b0110011) && (funct3 == 3'b110) && (funct7 == 7'b0000000);
  wire _i_and  = (opcode == 7'b0110011) && (funct3 == 3'b111) && (funct7 == 7'b0000000);

  wire _fence  = (opcode == 7'b0001111) && (_rd == 5'b00000) && (funct3 == 7'b0000000) && (_rs1 == 5'b00000) && (instr_raw[31:28] == 4'b0000);
  wire _fencei = (opcode == 7'b0001111) && (instr_raw[31:7] == 25'b0000000000000000000100000);
  wire _ecall  = (opcode == 7'b1110011) && (instr_raw[31:7] == 25'b0000000000000000000000000);
  wire _ebreak = (opcode == 7'b1110011) && (instr_raw[31:7] == 25'b0000000000010000000000000);
  wire _csrrw  = (opcode == 7'b1110011) && (funct3 == 3'b001);
  wire _csrrs  = (opcode == 7'b1110011) && (funct3 == 3'b010);
  wire _csrrc  = (opcode == 7'b1110011) && (funct3 == 3'b011);
  wire _csrrwi = (opcode == 7'b1110011) && (funct3 == 3'b101);
  wire _csrrsi = (opcode == 7'b1110011) && (funct3 == 3'b110);
  wire _csrrci = (opcode == 7'b1110011) && (funct3 == 3'b111);

  // rv32m
  wire _mul    = (opcode == 7'b0110011) && (funct3 == 3'b000);
  wire _mulh   = (opcode == 7'b0110011) && (funct3 == 3'b001);
  wire _mulhsu = (opcode == 7'b0110011) && (funct3 == 3'b010);
  wire _mulhu  = (opcode == 7'b0110011) && (funct3 == 3'b011);
  wire _div    = (opcode == 7'b0110011) && (funct3 == 3'b100);
  wire _divu   = (opcode == 7'b0110011) && (funct3 == 3'b101);
  wire _rem    = (opcode == 7'b0110011) && (funct3 == 3'b110);
  wire _remu   = (opcode == 7'b0110011) && (funct3 == 3'b111);

  // privileged instructions
  // wire _uret   = (opcode == 7'b1110011) && (instr_raw[31:7] == 25'b0000000000100000000000000);
  // wire _sret   = (opcode == 7'b1110011) && (instr_raw[31:7] == 25'b0001000000100000000000000);
  wire _mret   = (opcode == 7'b1110011) && (instr_raw[31:7] == 25'b0011000000100000000000000);

  // wire _wfi    = (opcode == 7'b1110011) && (instr_raw[31:7] == 25'b0001000001010000000000000);

  // control flags
  wire _is_store            = (_sb || _sw);
  wire _is_load             = (_lw || _lbu);
  wire _is_conditional_jump = (_beq || _bne || _blt || _bge || _bltu || _bgeu);
  wire _is_illegal_instr    = !(_lui || _auipc || _jal || _jalr
                              || _beq || _bne || _blt || _bge || _bltu || _bgeu
                              || _lb || _lh || _lw || _lbu || _lhu
                              ||_sb || _sh || _sw
                              || _addi || _slti || _sltiu || _xori || _ori || _andi || _slli || _srli || _srai
                              || _add || _sub || _sll || _slt || _sltu || _i_xor || _srl || _sra || _i_or || _i_and
                              || _fence || _fencei || _ecall || _ebreak
                              || _csrrw || _csrrs || _csrrc || _csrrwi || _csrrsi || _csrrci
                              || _mul || _mulh || _mulhsu || _mulhu || _div || _divu || _rem || _remu
                              || _mret);

  reg  _completed;
  assign completed = _completed & !enabled;

  wire [19:0] _imm_pn = instr_raw[31] ? ~20'b0 : 20'b0;

  always @(posedge clk) begin
    if (rstn) begin
      if (enabled) begin
        _completed <= 1;

        instr.rd   <= (r_type || i_type || u_type || j_type) ? _rd : 5'b00000;
        instr.rs1  <= (r_type || i_type || s_type || b_type) ? _rs1 : 5'b00000;
        instr.rs2  <= (r_type || s_type || b_type) ? _rs2 : 5'b00000;
        instr.imm  <= i_type ? {_imm_pn, instr_raw[31:20]} :
                      s_type ? {_imm_pn, instr_raw[31:25], instr_raw[11:7]} :
                      b_type ? {_imm_pn[18:0], instr_raw[31], instr_raw[7], instr_raw[30:25], instr_raw[11:8], 1'b0} :
                      u_type ? {instr_raw[31:12], 12'b0} :
                      j_type ? {_imm_pn[10:0], instr_raw[31], instr_raw[19:12], instr_raw[20], instr_raw[30:21], 1'b0} :
                      32'b0;
        instr.pc   <= pc;
        instr.zimm <= need_zimm ? {27'b0, _rs1} : 32'b0;
        instr.raw  <= instr_raw;

        instr.lui    <= _lui;
        instr.auipc  <= _auipc;

        instr.jal    <= _jal;
        instr.jalr   <= _jalr;

        instr.beq    <= _beq;
        instr.bne    <= _bne;
        instr.blt    <= _blt;
        instr.bge    <= _bge;
        instr.bltu   <= _bltu;
        instr.bgeu   <= _bgeu;

        instr.lb     <= _lb;
        instr.lh     <= _lh;
        instr.lw     <= _lw;
        instr.lbu    <= _lbu;
        instr.lhu    <= _lhu;
        instr.sb     <= _sb;
        instr.sh     <= _sh;
        instr.sw     <= _sw;

        instr.addi   <= _addi;
        instr.slti   <= _slti;
        instr.sltiu  <= _sltiu;
        instr.xori   <= _xori;
        instr.ori    <= _ori;
        instr.andi   <= _andi;
        instr.slli   <= _slli;
        instr.srli   <= _srli;
        instr.srai   <= _srai;

        instr.add    <= _add;
        instr.sub    <= _sub;
        instr.sll    <= _sll;
        instr.slt    <= _slt;
        instr.sltu   <= _sltu;
        instr.i_xor  <= _i_xor;
        instr.srl    <= _srl;
        instr.sra    <= _sra;
        instr.i_or   <= _i_or;
        instr.i_and  <= _i_and;

        instr.fence  <= _fence;
        instr.fencei <= _fencei;
        instr.ecall  <= _ecall;
        instr.ebreak <= _ebreak;
        instr.csrrw  <= _csrrw;
        instr.csrrs  <= _csrrs;
        instr.csrrc  <= _csrrc;
        instr.csrrwi <= _csrrwi;
        instr.csrrsi <= _csrrsi;
        instr.csrrci <= _csrrci;

        // rv32m
        instr.mul    <= _mul;
        instr.mulh   <= _mulh;
        instr.mulhsu <= _mulhsu;
        instr.mulhu  <= _mulhu;
        instr.div    <= _div;
        instr.divu   <= _divu;
        instr.rem    <= _rem;
        instr.remu   <= _remu;

        instr.mret   <= _mret;

        // control flags
        instr.is_store            <= _is_store;
        instr.is_load             <= _is_load;
        instr.is_csr              <= _is_csr;
        instr.is_conditional_jump <= _is_conditional_jump;
        instr.is_illegal_instr    <= _is_illegal_instr;
      end
    end else begin
      _completed <= 0;
      instr <= '{ default:0 };
    end
  end
endmodule

`default_nettype wire