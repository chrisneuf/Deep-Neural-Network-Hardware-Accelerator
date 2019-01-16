module dnn_bonus(input logic clk, input logic rst_n,
                 // slave (CPU-facing)
                 output logic slave_waitrequest,
                 input logic [3:0] slave_address,
                 input logic slave_read, output logic [31:0] slave_readdata,
                 input logic slave_write, input logic [31:0] slave_writedata,
                 // master (SDRAM-facing)
                 input logic master_waitrequest,
                 output logic [31:0] master_address,
                 output logic master_read, input logic [31:0] master_readdata, input logic master_readdatavalid,
                 output logic master_write, output logic [31:0] master_writedata);

    // your code here

endmodule: dnn_bonus
