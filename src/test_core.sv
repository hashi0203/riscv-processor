`timescale 1ns / 100ps
`default_nettype none

module test_core();
    logic clk;
    wire rstn = 1;
    wire [31:0] pc;
    wire [1:0] state;
    wire [31:0] register [31:0];
    int i, r;

    core _core(clk, rstn, pc, state, register);

    initial begin
      // $dumpfile("test_core.vcd");
      // $dumpvars(0);

      $display("start of checking module core");
      $display("difference message format");

      clk = 0;
      for (i=0; i<300; i++) begin
        #10
        clk = ~clk;
        if (state == 0) begin
          $display("pc: %d", pc[5:0]);
          $display("state: %d", state);
          $display("register:");
          for (r=0; r<8; r++) begin
            $write("%d: %d, ", r, register[r][5:0]);
          end
          $display("%d: %d", r, register[r][5:0]);
        end
      end

      $display("end of checking module core");
      $finish;
    end
endmodule

`default_nettype wire