module tb_wordcopy();

logic clk, rst_n;
logic slave_waitrequest, slave_read, slave_write;
logic [31:0] slave_readdata, slave_writedata;
logic [3:0] slave_address;
logic master_waitrequest, master_readdatavalid, master_read, master_write;
logic [31:0] master_address, master_readdata, master_writedata;

wire [5:0] state = dut.state;

wordcopy dut(.*);
tb_sdram sdram(.*);


initial begin
#10;
rst_n = 1;
slave_write = 0;
slave_read = 0;
clk = 1; #5; clk = 0; #5;
clk = 1; #5; clk = 0; #5;
clk = 1; #5; clk = 0; #5;
clk = 1; #5; clk = 0; #5;
rst_n = 0;
clk = 1; #5; clk = 0; #5;
rst_n = 1;
clk = 1; #5; clk = 0; #5;

assert(dut.state === dut.SETUP);

slave_write = 1;
slave_address = 1;
slave_writedata = 4;
clk = 1; #5; clk = 0; #5;

slave_write = 1;
slave_address = 2;
slave_writedata = 6;
clk = 1; #5; clk = 0; #5;

slave_write = 1;
slave_address = 3;
slave_writedata = 4;
clk = 1; #5; clk = 0; #5;

slave_write = 1;
slave_address = 0;
slave_writedata = 4;
clk = 1; #5; clk = 0; #5;
clk = 1; #5; clk = 0; #5;

assert(dut.state === dut.STARTCOPY);
slave_write = 0;
slave_read = 1;
while(dut.state == dut.STARTCOPY) begin
	clk = 1; #5; clk = 0; #5;
end
assert(dut.state === dut.READWORD);

while(dut.state == dut.READWORD) begin
	clk = 1; #5; clk = 0; #5;
end
assert(dut.state === dut.WRITEWORD);

while(dut.state == dut.WRITEWORD) begin
	clk = 1; #5; clk = 0; #5;
end
assert(dut.state === dut.INCREMENT);

while(dut.state == dut.INCREMENT) begin
	clk = 1; #5; clk = 0; #5;
end
assert(dut.state === dut.STARTCOPY);

while(dut.state != dut.FINISHEDCOPY) begin
	clk = 1; #5; clk = 0; #5;
end

assert(dut.slave_waitrequest === 1'b0);
assert(dut.nextstate === dut.SETUP);

while(dut.state == dut.FINISHEDCOPY) begin
	clk = 1; #5; clk = 0; #5;
end

assert(dut.state === dut.SETUP);

rst_n = 1;
slave_write = 0;
slave_read = 0;
clk = 1; #5; clk = 0; #5;
clk = 1; #5; clk = 0; #5;
clk = 1; #5; clk = 0; #5;
clk = 1; #5; clk = 0; #5;
rst_n = 0;
clk = 1; #5; clk = 0; #5;
rst_n = 1;
clk = 1; #5; clk = 0; #5;

assert(dut.state === dut.SETUP);

slave_write = 1;
slave_address = 1;
slave_writedata = 4;
clk = 1; #5; clk = 0; #5;

slave_write = 1;
slave_address = 2;
slave_writedata = 6;
clk = 1; #5; clk = 0; #5;

slave_write = 1;
slave_address = 3;
slave_writedata = 4;
clk = 1; #5; clk = 0; #5;

slave_write = 1;
slave_address = 0;
slave_writedata = 4;
clk = 1; #5; clk = 0; #5;
clk = 1; #5; clk = 0; #5;

assert(dut.state === dut.STARTCOPY);
slave_write = 0;
slave_read = 1;
while(dut.state == dut.STARTCOPY) begin
	clk = 1; #5; clk = 0; #5;
end
assert(dut.state === dut.READWORD);

while(dut.state == dut.READWORD) begin
	clk = 1; #5; clk = 0; #5;
end
assert(dut.state === dut.WRITEWORD);

while(dut.state == dut.WRITEWORD) begin
	clk = 1; #5; clk = 0; #5;
end
assert(dut.state === dut.INCREMENT);

while(dut.state == dut.INCREMENT) begin
	clk = 1; #5; clk = 0; #5;
end
assert(dut.state === dut.STARTCOPY);

while(dut.state != dut.FINISHEDCOPY) begin
	clk = 1; #5; clk = 0; #5;
end

assert(dut.slave_waitrequest === 1'b0);
assert(dut.nextstate === dut.SETUP);

while(dut.state == dut.FINISHEDCOPY) begin
	clk = 1; #5; clk = 0; #5;
end

assert(dut.state === dut.SETUP);


end
endmodule: tb_wordcopy

module tb_sdram(input logic clk, input logic rst_n, output logic master_waitrequest, input logic [31:0] master_address,
		        input logic master_read, output logic [31:0] master_readdata, output logic master_readdatavalid,
		        input logic master_write, input logic [31:0] master_writedata);

enum {IDLE, GET, POST} state;
logic [32:0] address;
logic [4:0] count;
logic write;


always_ff @(posedge clk or negedge rst_n) begin
    if(rst_n == 1'b0) begin
        master_readdatavalid <= 1'b0;
        master_readdata <= 32'd0;
        master_waitrequest <= 1'b1;
        count <= 5'd0;
        state <= IDLE;
    end
    else begin
        case(state)
            IDLE: begin
                master_readdatavalid <= 1'b0;
                master_readdata <= 32'd0;
                address <= master_address;
                if((master_read == 1'b1 || master_write == 1'b1) && count == 5'd2) begin
                    state <= GET;
                    write = master_write ? 1'b1 : 1'b0;
                    master_waitrequest <= 1'b0;
                    count = 5'd0;
                end
                else begin
                    state <= IDLE;
                    master_waitrequest <= 1'b1;
                    count = count + 5'd1;
                end
            end
            GET: begin
                master_waitrequest = 1'b1;
                master_readdatavalid <= 1'b0;
                master_readdata <= 32'd0;
                if(count == 5'd3) begin
                    state <= write ? IDLE : POST;
                    count = 5'd0;
                end
                else begin
                    count <= count + 5'd1;
                    state <= GET;
                end
            end
            POST: begin
                master_readdatavalid <= 1'b1;
                master_waitrequest <= 1'b1;
                master_readdata <= {address[15:0],address[15:0]};
                count <= 5'd0;
                state <= IDLE;
            end
            default:
                state <= IDLE;
        endcase
    end
end

endmodule: tb_sdram
