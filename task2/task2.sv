module task2(input logic CLOCK_50, input logic [3:0] KEY, // KEY[3] is async active-low reset
             input logic [9:0] SW, output logic [9:0] LEDR,
             output logic DRAM_CLK, output logic DRAM_CKE,
             output logic DRAM_CAS_N, output logic DRAM_RAS_N, output logic DRAM_WE_N,
             output logic [12:0] DRAM_ADDR, output logic [1:0] DRAM_BA, output logic DRAM_CS_N,
             inout [15:0] DRAM_DQ, output logic DRAM_UDQM, output logic DRAM_LDQM,
             output logic [6:0] HEX0, output logic [6:0] HEX1, output logic [6:0] HEX2,
             output logic [6:0] HEX3, output logic [6:0] HEX4, output logic [6:0] HEX5);
    assign HEX1 = 7'b1111111;
    assign HEX2 = 7'b1111111;
    assign HEX3 = 7'b1111111;
    assign HEX4 = 7'b1111111;
    assign HEX5 = 7'b1111111;
    assign LEDR[8:0] = 9'b000000000;
    dnn_accel_system sys(.clk_clk(CLOCK_50), .reset_reset_n(KEY[3]),
                         .pll_locked_export(LEDR[9]),
                         .sdram_clk_clk(DRAM_CLK),
                         .sdram_addr(DRAM_ADDR),
                         .sdram_ba(DRAM_BA),
                         .sdram_cas_n(DRAM_CAS_N),
                         .sdram_cke(DRAM_CKE),
                         .sdram_cs_n(DRAM_CS_N),
                         .sdram_dq(DRAM_DQ),
                         .sdram_dqm({DRAM_UDQM, DRAM_LDQM}),
                         .sdram_ras_n(DRAM_RAS_N),
                         .sdram_we_n(DRAM_WE_N),
                         .hex_export(HEX0));
endmodule: task2

