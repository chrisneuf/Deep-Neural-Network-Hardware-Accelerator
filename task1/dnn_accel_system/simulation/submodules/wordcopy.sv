module wordcopy(input logic clk, input logic rst_n,
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

	logic [31:0] numwords, dest, src, checkword, count, copyword;
	logic countplus, getdata;
	enum {SETUP, STARTCOPY, READWORD, WRITEWORD, INCREMENT, FINISHEDCOPY} state, nextstate;

	always_ff @(posedge clk or negedge rst_n) begin
		if (rst_n == 0) begin
			numwords <= 32'd0;
			dest <= 32'd0;
			src <= 32'd0;
			count <= 32'd0;
			copyword <= 32'd0;
			state <= SETUP;
		end
		else begin
			state <= nextstate;
			if(slave_write == 1'b1) begin
				case(slave_address)
					4'd0: begin
						checkword <= slave_writedata;
						count <= 32'd0;
					end
					4'd1: begin
						dest <= slave_writedata;
					end
					4'd2: begin
						src <= slave_writedata;
					end
					4'd3: begin
						numwords <= slave_writedata;
					end
				endcase
			end
			else begin 
				if(getdata) begin
					copyword <= master_readdata;	
				end
				if(countplus) begin
					count <= count + 32'd1;
				end
			end
		end
	end

	assign slave_readdata = 32'd0;
	always_comb begin
		case(state)
			SETUP: begin
				slave_waitrequest = 1'b0;
				countplus = 1'b0;
				master_writedata = 32'd0;
				master_address = 32'd0;
				master_read = 1'd0;
				master_write = 1'd0;
				getdata = 1'b0;
				nextstate = slave_write && slave_address == 4'd0 ? STARTCOPY : SETUP;
			end
			STARTCOPY: begin
				slave_waitrequest = 1'd1;
				countplus = 1'b0;
				master_write = 1'b0;
				master_writedata = 32'd0;
				getdata = 1'b0;
				if(count < numwords) begin
					master_read = 1'b1;
					master_address = src + (count << 2);
					nextstate = master_waitrequest ? STARTCOPY : READWORD;
				end
				else begin
					nextstate = FINISHEDCOPY;
					master_address = 32'd0;
					master_read = 1'b0;
				end
			end
			READWORD: begin
				countplus = 1'b0;
				getdata = 1'b1;
				slave_waitrequest = 1'd1;
				master_writedata = 32'd0;
				master_address = src + (count << 2);
				master_write = 1'b0;
				master_read = 1'b0;
				nextstate = master_readdatavalid ? WRITEWORD : READWORD;
			end
			WRITEWORD: begin
				countplus = 1'b0;
				slave_waitrequest = 1'd1;
				master_address = dest + (count << 2);
				master_write = 1'b1;
				getdata = 1'b0;
				master_read = 1'b0;
				master_writedata = copyword;
				nextstate = master_waitrequest ? WRITEWORD : INCREMENT;
			end
			INCREMENT: begin
				countplus = 1'b1;
				master_writedata = 32'd0;
				getdata = 1'b0;
				slave_waitrequest = 1'd1;
				master_write = 1'b0;
				master_read = 1'b0;
				master_address = 32'd0;
				nextstate = STARTCOPY;
			end
			FINISHEDCOPY: begin
				countplus = 1'b0;
				getdata = 1'b0;
				slave_waitrequest = 1'd0;
				master_writedata = 32'd0;
				master_write = 1'b0;
				master_read = 1'b0;
				master_address = 32'd0;
				nextstate = SETUP;
			end
			default: begin
				countplus = 1'b0;
				getdata = 1'b0;
				slave_waitrequest = 1'b0;
				master_writedata = 32'd0;
				master_address = 32'd0;
				master_read = 1'd0;
				master_write = 1'd0;
			end	
		endcase
	end
endmodule: wordcopy
