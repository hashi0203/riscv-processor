`default_nettype none
`include "def.sv"

module core
  ( input  wire       clk,
    input  wire       rstn,

    output reg [31:0] pc_out,
    output reg [31:0] rd_out,
    output reg [31:0] preds [2:0],
    output reg [31:0] regs [31:0],
    output reg        completed );

    reg [31:0] pc;

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

    integer i;
    task init;
      begin
        pc <= 32'b0;
        preds[0] <= 32'b0;
        preds[1] <= 32'b0;
        preds[2] <= 32'b0;

        fetch_enabled <= 1;
        decode_enabled <= 0;
        execute_enabled <= 0;
        write_enabled <= 0;

        fetch_rstn <= 1;
        decode_rstn <= 0;
        execute_rstn <= 0;
        write_rstn <= 0;

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
       end
    endtask

    task set_fd_reg;
      begin
        pc_fd_in <= pc;
        instr_fd_in <= instr_fd_out;
        global_pred_fd <= global_pred;
      end
    endtask

    task set_de_reg;
      begin
        rs1_de_in <= (execute_enabled && rs1_addr == instr_de.rd) ?
                     rd_ew_out : rs1_data;
        rs2_de_in <= (execute_enabled && rs2_addr == instr_de.rd) ?
                     rd_ew_out : rs2_data;
        global_pred_de <= global_pred_fd;
      end
    endtask

    task set_ew_reg;
      begin
        rd_ew_in <= rd_ew_out;
      end
    endtask

    initial begin
      init();
    end

    always @(posedge clk) begin
      pc_out <= pc;
      rd_out <= rd_ew_out;
      completed <= instr_ew.pc == 32'd35;

      if (rstn) begin
        if (pred_fail) begin
          bht[pc_e[7:0]][global_pred_de] <= is_jump ? bh_t : bh_nt;
          global_pred <= {global_pred[0], is_jump};
          preds[0] <= preds[0] + 1;
          preds[2] <= preds[2] + 1;
          if (is_jump) begin
            btac[pc_e[7:0]] <= {pc_e[31:8], jump_dest};
          end

          pc <= jump_dest;

          decode_enabled <= 0;
          execute_enabled <= 0;
          write_enabled <= execute_enabled;

          decode_rstn <= 0;
          execute_rstn <= 0;
          write_rstn <= execute_rstn;
        end else begin
          if (pred_succeed) begin
            bht[pc_e[7:0]][global_pred_de] <= is_jump ? bh_t : bh_nt;
            global_pred <= {global_pred[0], is_jump};
            preds[0] <= preds[0] + 1;
            preds[1] <= preds[1] + 1;
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