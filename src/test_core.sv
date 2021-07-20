`timescale 1ns / 100ps
`default_nettype none

module test_core();
  logic clk;
  wire  rstn = 1;

  logic ext_intr;
  logic timer_intr;

  wire [31:0] pc;
  wire [31:0] instrs [3:0];
  wire [31:0] preds  [2:0];
  wire [31:0] regs   [31:0];
  wire        completed;

  int max_itr      = 100000;
  int max_reg_show = 15;
  int i, r;

  core _core(clk, rstn, ext_intr, timer_intr, pc, instrs, preds, regs, completed);

  initial begin
    // $dumpfile("test_core.vcd");
    // $dumpvars(0);

    $display("############### start of checking module core ###############");

    clk = 0;
    ext_intr = 0;
    timer_intr = 0;
    for (i = 0; i < max_itr; i++) begin
      #10
      clk = ~clk;

      if (i==1000) begin
        ext_intr = 1;
      end
      if (i==1200) begin
        ext_intr = 0;
      end

      if (i==10000) begin
        timer_intr = 1;
      end
      if (i==10200) begin
        timer_intr = 0;
      end

      if (completed) begin
        $display("iteration    : %5d", i);
        $display("pc           : %5d", pc);
        $display("instructions : total %5d, normal  %5d, exception %5d, others %5d", instrs[0], instrs[1], instrs[2], instrs[3]);
        $display("prediction   : total %5d, succeed %5d, fail      %5d",  preds[0],  preds[1],  preds[2]);
        $display("register     :");
        for (r = 0; r < max_reg_show; r++) begin
          if (r % 4 == 3) begin
            $display("    r%02d: %4d,", r, $signed(regs[r]));
          end else begin
            $write("    r%02d: %4d,", r, $signed(regs[r]));
          end
        end
        $display("    r%02d: %4d", r, $signed(regs[r]));
        break;
      end
    end

    $display("################# end of checking module core ###############");
    $finish;
  end
endmodule

`default_nettype wire