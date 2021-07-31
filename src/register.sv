`default_nettype none

module register #(parameter MEM_SIZE = 32'd1024)
  ( input  wire        clk,
    input  wire        rstn,
    input  wire        r_enabled,

    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,

    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,

    input  wire        w_enabled,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,

    output reg  [31:0] regs_out [31:0] );

  reg [31:0] regs [31:0];

  integer i;
  initial begin
    for (i=0; i<32; i++) begin
      if (i == 2) begin
        regs[2] <= MEM_SIZE << 1;
      end else begin
        regs[i] <= 0;
      end
    end
  end

  assign rs1_data = (rstn && r_enabled) ? ((w_enabled && rd_addr != 5'b0 && rd_addr == rs1_addr) ? rd_data : regs[rs1_addr]) : 32'b0;
  assign rs2_data = (rstn && r_enabled) ? ((w_enabled && rd_addr != 5'b0 && rd_addr == rs2_addr) ? rd_data : regs[rs2_addr]) : 32'b0;

  always @(posedge clk) begin
    if (rstn) begin
      if (w_enabled) begin
        regs[rd_addr] <= rd_data;
      end
    end
    regs_out <= regs;
  end
endmodule

`default_nettype wire