`default_nettype none
`include "def.sv"

module core
  ( input  wire       clk,
    input  wire       rstn,

    input  wire       ext_intr,
    input  wire       timer_intr,

    output reg [31:0] pc_out,
    output reg [31:0] preds [2:0],
    output reg [31:0] regs [31:0],
    output reg        completed );

  reg [31:0] pc;
  reg        state;    // 0: default, 1: trap (exception, interrupt)
  reg [1:0]  cpu_mode; // 0: user, 3: machine

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
  wire [4:0]   rs1_addr;
  wire [4:0]   rs2_addr;
  wire [11:0]  csr_addr;

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
      .csr(csr_addr) );

  // execute
  reg  execute_enabled;
  reg  execute_rstn;
  wire execute_completed;

  reg [31:0] rs1_de_in;
  reg [31:0] rs2_de_in;
  reg [31:0] csr_de_in;

  instructions instr_ew;
  // reg  [31:0] rs1_ew_out;
  // reg  [31:0] rs2_ew_out;
  wire [31:0] rd_ew_out;
  wire [31:0] csrd_ew_out;
  wire        is_jump;
  wire [31:0] jump_dest;

  execute _execute
    ( .clk(clk),
      .rstn(rstn & execute_rstn),

      .enabled(execute_enabled),
      .instr(instr_de),
      .rs1(rs1_de_in),
      .rs2(rs2_de_in),
      .csr(csr_de_in),

      .completed(execute_completed),
      .instr_out(instr_ew),
      // .rs1_out(rs1_ew_out),
      // .rs2_out(rs2_ew_out),

      .rd(rd_ew_out),
      .csrd(csrd_ew_out),
      .is_jump(is_jump),
      .jump_dest(jump_dest) );


  // write
  reg  write_enabled;
  reg  write_rstn;
  wire write_completed;

  reg [31:0]  rd_ew_in;
  reg [31:0]  csrd_ew_in;

  wire        reg_w_enabled;
  wire [4:0]  reg_w_addr;
  wire [31:0] reg_w_data;

  wire        csr_w_enabled;
  wire [11:0] csr_w_addr;
  wire [31:0] csr_w_data;

  write _write
    ( .clk(clk),
      .rstn(rstn & write_rstn),
      .enabled(write_enabled),
      .instr(instr_ew),
      .reg_data(rd_ew_in),
      .csr_data(csrd_ew_in),

      .reg_w_enabled(reg_w_enabled),
      .reg_w_addr(reg_w_addr),
      .reg_w_data(reg_w_data),
      .csr_w_enabled(csr_w_enabled),
      .csr_w_addr(csr_w_addr),
      .csr_w_data(csr_w_data),
      .completed(write_completed) );

  wire [31:0] rs1_data;
  wire [31:0] rs2_data;

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

  // branch prediction (Two-level adaptive predictor)
  wire [6:0] opcode = instr_fd_out[6:0];
  wire _jal         = (opcode == 7'b1101111);
  wire _jalr        = (opcode == 7'b1100111);
  wire _cond_jump   = (opcode == 7'b1100011);
  wire is_jump_f    = (_jal || _jalr || _cond_jump);

  reg [1:0]  bht  [255:0] [3:0];
  reg [55:0] btac [255:0];
  reg [1:0]  global_pred;
  reg [1:0]  global_pred_fd;
  reg [1:0]  global_pred_de;

  wire [31:0] pred_jump_dest = (bht[pc[7:0]][global_pred][1] && btac[pc[7:0]][55:32] == pc[31:8]) ?
                               btac[pc[7:0]][31:0] : pc + 1;

  wire is_jump_e = (execute_enabled && (instr_de.jal || instr_de.jalr || instr_de.is_conditional_jump));
  wire pred_succeed = (is_jump_e && jump_dest == pc_fd_in);
  wire pred_fail    = (is_jump_e && jump_dest != pc_fd_in);
  wire [31:0] pc_e  = instr_de.pc;
  // status when branch is taken
  wire [1:0]  bh_t  = (bht[pc_e[7:0]][global_pred_de] == 2'b00) ? 2'b01 :
                      (bht[pc_e[7:0]][global_pred_de] == 2'b01) ? 2'b10 :
                      2'b11;
  // status when branch is not taken
  wire [1:0]  bh_nt = (bht[pc_e[7:0]][global_pred_de] == 2'b11) ? 2'b10 :
                      (bht[pc_e[7:0]][global_pred_de] == 2'b10) ? 2'b01 :
                      2'b00;

  // csr operation
  csreg csr;

  task init_csr;
    begin
      csr.mstatus_mask <= 32'h601e19aa;
      csr.mie_mask     <= {20'b0, 4'b1010, 4'b1010, 4'b1010};
      csr.mip_mask     <= {20'b0, 4'b1000, 4'b1000, 4'b0000};

      csr.mstatus  <= 32'b0;
      // csr.mie      <= 32'b0;
      csr.mie      <= {20'b0, 4'b1010, 4'b1010, 4'b1010};
      // csr.mtvec    <= 32'b0;
      csr.mtvec    <= {30'd47, 2'b0};
      csr.mepc     <= 32'b0;
      csr.mcause   <= 32'b0;
      csr.mtval    <= 32'b0;
      csr.mip      <= 32'b0;
    end
  endtask

  function [32:0] read_csr(input [11:0] r_addr);
    begin
      case (r_addr)
        12'h300: read_csr = {1'b1, csr.mstatus};
        12'h304: read_csr = {1'b1, csr.mie};
        12'h305: read_csr = {1'b1, csr.mtvec};
        12'h341: read_csr = {1'b1, csr.mepc};
        12'h342: read_csr = {1'b1, csr.mcause};
        12'h343: read_csr = {1'b1, csr.mtval};
        12'h344: read_csr = {1'b1, csr.mip};
        default: read_csr = {1'b0, 32'b0};
      endcase
    end
  endfunction

  function [32:0] rw_csr
    ( input        r_enabled,
      input [11:0] r_addr,

      input        w_enabled,
      input [4:0]  w_addr,
      input [31:0] w_data );

    rw_csr = r_enabled ?
             ((w_enabled && w_addr == r_addr) ? {1'b1, w_data} : read_csr(r_addr)) :
             33'b0;

    if (w_enabled) begin
      case (w_addr) // write w_data in csr
        12'h300: csr.mstatus <= (csr.mstatus & ~csr.mstatus_mask) | (w_data & csr.mstatus_mask);
        12'h304: csr.mie     <= (csr.mie & ~csr.mie_mask) | (w_data & csr.mie_mask);
        12'h305: if ((w_data & 32'b11) < 32'd2) begin csr.mtvec <= w_data; end
        12'h341: csr.mepc    <= w_data;
        12'h342: csr.mcause  <= w_data;
        12'h343: csr.mtval   <= w_data;
        12'h344: csr.mip     <= w_data;
      endcase
    end
  endfunction

  reg         is_csr_valid;
  // v_csr_data = {is_csr_valid, csr_data};
  wire [32:0] v_csr_data = rw_csr(decode_enabled, csr_addr, csr_w_enabled, csr_w_addr, csr_w_data);

  wire [31:0] _mip = (csr.mip & csr.mip_mask) | {20'b0, ext_intr, 3'b0, timer_intr, 3'b0, 4'b0};
  wire [31:0] _mie = csr.mie & csr.mie_mask;

  wire        _mstatus_tvm  = csr.mstatus[20];
  wire [1:0]  _mstatus_mpp  = csr.mstatus[12:11];
  wire        _mstatus_spp  = csr.mstatus[8];
  wire        _mstatus_mpie = csr.mstatus[7];
  wire        _mstatus_spie = csr.mstatus[5];
  wire        _mstatus_mie  = csr.mstatus[3];
  wire        _mstatus_sie  = csr.mstatus[1];

  wire [31:0] exception_vec_when_interrupted = (_mip[11] && _mie[11]) ? 32'd11 :
                                               (_mip[3]  && _mie[3] ) ? 32'd3  :
                                               (_mip[7]  && _mie[7] ) ? 32'd7  :
                                               // (_mip[9] && _mie[9])? 32'd9:
                                               // (_mip[1] && _mie[1])? 32'd1:
                                               // (_mip[5] && _mie[5])? 32'd5:
                                               32'd0;

  reg        is_exception;
  reg [3:0]  exception_code;
  reg [31:0] exception_tval;
  reg [31:0] pc_when_exception;
  reg [31:0] pc_when_interrupted;

  // wire       is_interrupted = |(_mip & _mie) && (cpu_mode < 2'd3 || (cpu_mode == 2'd3 && _mstatus_mie));
  wire       is_interrupted = |(_mip & _mie) && (cpu_mode < 2'd3);

  task set_mstatus_by_trap;
    begin
      csr.mstatus <= {csr.mstatus[31:13],
                      cpu_mode[1:0],      // mpp
                      csr.mstatus[10:8],
                      csr.mstatus[3],     // mpie
                      csr.mstatus[6:4],
                      1'b0,               // mie
                      csr.mstatus[2:0]};
    end
  endtask

  task set_mstatus_by_mret;
    begin
      csr.mstatus <= {csr.mstatus[31:13],
                      2'b0,               // mpp
                      csr.mstatus[10:8],
                      1'b1,               // mpie
                      csr.mstatus[6:4],
                      _mstatus_mpie,      // mie
                      csr.mstatus[2:0]};
    end
  endtask

  task set_csr_when_exception;
    begin
      csr.mcause  <= {28'b0, exception_code};
      csr.mepc    <= pc_when_exception + 1;
      csr.mtval   <= exception_tval;
      set_mstatus_by_trap();
    end
  endtask

  task set_csr_when_interrupted;
    begin
      csr.mcause <= {1'b1, exception_vec_when_interrupted[30:0]};
      csr.mepc   <= pc_when_interrupted;
      csr.mtval  <= 32'b0;
      set_mstatus_by_trap();
    end
  endtask

  // raise exception
  task raise_illegal_instr;
    begin
      is_exception      <= 1;
      exception_code    <= 4'd2;
      exception_tval    <= instr_de.raw;
      pc_when_exception <= instr_de.pc;
    end
  endtask

  task raise_ebreak;
    begin
      is_exception      <= 1;
      exception_code    <= 4'd3;
      exception_tval    <= instr_de.pc;
      pc_when_exception <= instr_de.pc;
    end
  endtask

  task raise_ecall;
    begin
      is_exception      <= 1'b1;
      exception_code    <= cpu_mode == 2'd3 ? 4'd11 :
                           cpu_mode == 2'd0 ? 4'd8  :
                           5'd16;
      exception_tval    <= 32'd0;
      pc_when_exception <= instr_de.pc;
    end
   endtask

  // pipeline register
  task set_fd_reg;
    begin
      pc_fd_in       <= pc;
      instr_fd_in    <= instr_fd_out;
      global_pred_fd <= global_pred;
    end
  endtask

  task set_de_reg;
    begin
      rs1_de_in      <= (execute_enabled && rs1_addr == instr_de.rd) ?
                        rd_ew_out : rs1_data;
      rs2_de_in      <= (execute_enabled && rs2_addr == instr_de.rd) ?
                        rd_ew_out : rs2_data;
      csr_de_in      <= (execute_enabled && csr_addr == instr_de.imm) ?
                        csrd_ew_out : v_csr_data[31:0];
      is_csr_valid   <= v_csr_data[32:32];
      global_pred_de <= global_pred_fd;
    end
  endtask

  task set_ew_reg;
    begin
      rd_ew_in   <= rd_ew_out;
      csrd_ew_in <= csrd_ew_out;
    end
  endtask

  // pipeline flush
  task flush_fd_reg;
    begin
      pc_fd_in       <= 32'b0;
      instr_fd_in    <= '{ default:0 };
      global_pred_fd <= 2'b0;
    end
  endtask

  task flush_de_reg;
    begin
      rs1_de_in      <= 32'b0;
      rs2_de_in      <= 32'b0;
      global_pred_de <= 2'b0;
    end
  endtask

  task flush_ew_reg;
    begin
      rd_ew_in <= 32'b0;
    end
  endtask

  task flush_stages_when_prediction_fails;
    begin
      decode_enabled  <= 0;
      execute_enabled <= 0;
      write_enabled   <= execute_enabled;

      decode_rstn     <= 0;
      execute_rstn    <= 0;
      write_rstn      <= execute_rstn;

      flush_fd_reg();
      flush_de_reg();
      set_ew_reg();
    end
  endtask

  task flush_stages_when_interrupted;
    begin
      fetch_enabled   <= 0;
      decode_enabled  <= 0;
      execute_enabled <= 0;
      write_enabled   <= execute_enabled;

      fetch_rstn      <= 0;
      decode_rstn     <= 0;
      execute_rstn    <= 0;
      write_rstn      <= execute_rstn;

      flush_fd_reg();
      flush_de_reg();
      set_ew_reg();
    end
  endtask

  task flush_stages_when_mret;
    begin
      decode_enabled  <= 0;
      execute_enabled <= 0;
      write_enabled   <= 0;

      decode_rstn     <= 0;
      execute_rstn    <= 0;
      write_rstn      <= 0;

      flush_fd_reg();
      flush_de_reg();
      flush_ew_reg();
    end
  endtask

  task flush_all_stages;
    begin
      fetch_enabled   <= 0;
      decode_enabled  <= 0;
      execute_enabled <= 0;
      write_enabled   <= 0;

      fetch_rstn      <= 0;
      decode_rstn     <= 0;
      execute_rstn    <= 0;
      write_rstn      <= 0;

      flush_fd_reg();
      flush_de_reg();
      flush_ew_reg();
    end
  endtask

  integer i;
  task init;
    begin
      pc       <= 32'b0;
      state    <= 0;
      cpu_mode <= 2'd0;
      preds[0] <= 32'b0;
      preds[1] <= 32'b0;
      preds[2] <= 32'b0;

      fetch_enabled   <= 1;
      decode_enabled  <= 0;
      execute_enabled <= 0;
      write_enabled   <= 0;

      fetch_rstn      <= 1;
      decode_rstn     <= 0;
      execute_rstn    <= 0;
      write_rstn      <= 0;

      for (i=0; i<256; i++) begin
        bht[i][0]  <= 2'b1;
        bht[i][1]  <= 2'b1;
        bht[i][2]  <= 2'b1;
        bht[i][3]  <= 2'b1;
        btac[i]    <= 56'b0;
      end
      global_pred    <= 2'b0;
      global_pred_fd <= 2'b0;
      global_pred_de <= 2'b0;

      init_csr();

      is_exception        <= 0;
      exception_code      <= 4'b0;
      exception_tval      <= 32'b0;
      pc_when_exception   <= 32'b0;
      pc_when_interrupted <= 32'b0;
    end
  endtask

  initial begin
    init();
  end

  always @(posedge clk) begin
    pc_out <= pc;
    completed <= instr_ew.pc == 32'd43;

    if (rstn) begin
      if (state) begin
        state         <= 0;
        cpu_mode      <= 2'd3;
        is_exception  <= 0;

        fetch_enabled <= 1;
        fetch_rstn    <= 1;

        if (is_exception) begin
          pc <= {2'b0, csr.mtvec[31:2]};
          set_csr_when_exception();
        end else begin // interrupted
          pc <= (csr.mtvec[1:0] == 2'b0) ? {2'b0, csr.mtvec[31:2]} :
                {2'b0, csr.mtvec[31:2]} + {27'b0, exception_vec_when_interrupted[4:0]};
          set_csr_when_interrupted();
        end
      end else begin // if (state)
        if (execute_enabled && (instr_de.is_illegal_instr || (instr_de.is_csr && !is_csr_valid))) begin
          state <= 1;
          raise_illegal_instr();
          flush_all_stages();
        end else if (execute_enabled && instr_de.mret) begin
          if (cpu_mode == 2'd3) begin
            state <= 0;
            cpu_mode <= 2'd0;
            set_mstatus_by_mret();

            pc <= csr.mepc;
            // pc <= _mepc;
            flush_stages_when_mret();
          end else begin
            state <= 1;
            raise_illegal_instr();
            flush_all_stages();
          end
        end else if (execute_enabled && instr_de.ecall) begin
          state <= 1;
          raise_ecall();
          flush_all_stages();
        end else if (execute_enabled && instr_de.ebreak) begin
          state <= 1;
          raise_ebreak();
          flush_all_stages();
        end else if (is_interrupted) begin
          state <= 1;
          flush_all_stages();
        end else if (pred_fail) begin
          bht[pc_e[7:0]][global_pred_de] <= is_jump ? bh_t : bh_nt;
          global_pred <= {global_pred[0], is_jump};
          preds[0] <= preds[0] + 1;
          preds[2] <= preds[2] + 1;
          if (is_jump) begin
            btac[pc_e[7:0]] <= {pc_e[31:8], jump_dest};
          end

          pc <= jump_dest;
          flush_stages_when_prediction_fails();
        end else begin
          if (pred_succeed) begin
            bht[pc_e[7:0]][global_pred_de] <= is_jump ? bh_t : bh_nt;
            global_pred <= {global_pred[0], is_jump};
            preds[0] <= preds[0] + 1;
            preds[1] <= preds[1] + 1;
          end

          pc <= (is_jump_f) ? pred_jump_dest : pc + 1;

          decode_enabled  <= fetch_enabled;
          execute_enabled <= decode_enabled;
          write_enabled   <= execute_enabled;

          decode_rstn     <= fetch_rstn;
          execute_rstn    <= decode_rstn;
          write_rstn      <= execute_rstn;

          set_fd_reg();
          set_de_reg();
          set_ew_reg();
        end

        if (cpu_mode == 2'd0 && execute_enabled && !is_interrupted) begin
          pc_when_interrupted <= jump_dest;
        end
      end // if (state)
    end else begin // if (rstn)
      init();
    end
  end
endmodule

`default_nettype wire