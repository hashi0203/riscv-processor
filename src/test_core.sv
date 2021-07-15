`timescale 1ns / 100ps
`default_nettype none

module test_core();
    logic clk;
    wire rstn = 1;
    wire [31:0] pc;
    wire [31:0] rd;
		wire [31:0] preds [2:0];
    wire [31:0] regs [31:0];
    int i, r;

    core _core(clk, rstn, pc, rd, preds, regs);

    initial begin
      // $dumpfile("test_core.vcd");
      // $dumpvars(0);

      $display("start of checking module core");
      $display("difference message format");

      clk = 0;
      for (i=0; i<9760; i++) begin
        #10
        clk = ~clk;
        if (pc == 35) begin
          $display("pc: %d", pc[5:0]);
          // $display("rd: %3d", $signed(rd));
          $display("prediction: total %4d, succeed %4d, fail %4d", preds[0], preds[1], preds[2]);
          $display("register:");
          for (r=0; r<15; r++) begin
            $write("r%02d: %3d,    ", r, $signed(regs[r]));
          end
          $display("r%02d: %3d", r, $signed(regs[r]));
        end
      end

      $display("end of checking module core");
      $finish;
    end
endmodule

`default_nettype wire