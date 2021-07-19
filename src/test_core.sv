`timescale 1ns / 100ps
`default_nettype none

module test_core();
  logic clk;
  wire rstn = 1;
  wire [31:0] pc;
  logic ext_intr;
  logic timer_intr;
  wire [31:0] preds [2:0];
  wire [31:0] regs [31:0];
  wire completed;
  int i, r;

  core _core(clk, rstn, ext_intr, timer_intr, pc, preds, regs, completed);

  initial begin
    // $dumpfile("test_core.vcd");
    // $dumpvars(0);

    $display("start of checking module core");
    $display("difference message format");

    clk = 0;
    ext_intr = 0;
    timer_intr = 0;
    for (i=0; i<20000; i++) begin
      #10
      clk = ~clk;
      if (i==100) begin
        ext_intr = 1;
      end
      if (i==200) begin
        ext_intr = 0;
      end
      if (completed) begin
        $display("iteration: %5d", i);
        $display("pc: %5d", pc);
        $display("prediction: total %4d, succeed %4d, fail %4d", preds[0], preds[1], preds[2]);
        $display("register:");
        for (r=0; r<15; r++) begin
          $write("r%02d: %3d,    ", r, $signed(regs[r]));
        end
        $display("r%02d: %3d", r, $signed(regs[r]));
        break;
      end
    end

    $display("end of checking module core");
    $finish;
  end
endmodule

`default_nettype wire