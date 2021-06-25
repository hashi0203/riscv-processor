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
    wire [3:0] a = 4'b1100;

    initial begin
      // $dumpfile("test_core.vcd");
      // $dumpvars(0);

      $display("start of checking module core");
      $display("difference message format");

      clk = 0;
      for (i=0; i<45700; i++) begin
        #10
        clk = ~clk;
        if (state == 0 && pc == 35) begin
          $display("pc: %d", pc[5:0]);
          $display("state: %d", state);
          $display("register:");
          for (r=0; r<15; r++) begin
            $write("r%02d: %3d,    ", r, $signed(register[r]));
          end
          $display("r%02d: %3d", r, $signed(register[r]));
        end
      end

      $display("end of checking module core");
      $finish;
    end
endmodule

`default_nettype wire