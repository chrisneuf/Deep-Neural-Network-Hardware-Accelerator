module dnn(input logic clk, input logic rst_n,
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

    logic [31:0] bias_addr, weight_addr, inactivation_addr, outactivation_addr, reserved_addr, relu, length, reserved, count;
    logic signed [63:0] weight, inactivation, sum;
    logic signed [31:0] outactivation;
    logic [2:0] getdata, running;
	enum {SETUP, REQBIAS, RCVBIAS, REQWEIGHT, RCVWEIGHT, REQINPUT, RCVINPUT, CALC, RELU, WRITEOUPUT} state, nextstate;
    assign running = state == SETUP ? 1'b0 : 1'b1;
	always_ff @(posedge clk or negedge rst_n) begin
		if (rst_n == 0) begin
			count <= 32'd0;
			bias_addr <= 32'd0;
			weight <= 64'd0;
			weight_addr <= 32'd0;
            inactivation <= 64'd0;
			inactivation_addr <= 32'd0;
            outactivation <= 32'd0;
            outactivation_addr <= 32'd0;
            reserved_addr <= 32'd0;
            reserved <= 32'd0;
            sum <= 32'd0;
            relu <= 32'd0;
			state <= SETUP;
		end
		else begin
			state <= nextstate;
			if(slave_write == 1'b1 && running == 1'b0) begin
				case(slave_address)
					4'd0: begin
						count <= 32'd0;
                        sum <= 32'd0;
					end
					4'd1: begin
						bias_addr <= slave_writedata;
					end
					4'd2: begin
						weight_addr <= slave_writedata;
					end
					4'd3: begin
						inactivation_addr <= slave_writedata;
					end
					4'd4: begin
						outactivation_addr <= slave_writedata;
					end
					4'd5: begin
						length <= slave_writedata;
					end
					4'd6: begin
						reserved_addr <= slave_writedata;
					end
					4'd7: begin
						relu <= slave_writedata;
					end
				endcase
			end
			else begin 
				case(getdata) 
                    3'd1: sum <= $signed(master_readdata);
                    3'd2: weight <= $signed(master_readdata);
                    3'd3: inactivation <= $signed(master_readdata);
                    3'd4: begin 
                        sum <= sum + ((weight*inactivation) >>> 16);
                        count <= count + 32'd1;
                    end
                    3'd5: outactivation <= $signed(sum);
                    3'd6: outactivation <= sum < 0 ? 32'd0 : $signed(sum);
                endcase
			end
		end
	end

	assign slave_readdata = 32'd0;
	always_comb begin
		case(state)
			SETUP: begin
				slave_waitrequest = 1'b0;
				master_writedata = 32'd0;
				master_address = 32'd0;
				master_read = 1'd0;
				master_write = 1'd0;
				getdata = 3'd0;
				nextstate = slave_write && slave_address == 4'd0 ? REQBIAS : SETUP;
			end
			REQBIAS: begin
				slave_waitrequest = 1'd1;
				master_write = 1'b0;
				master_writedata = 32'd0;
				getdata = 3'd0;
				if(count < length) begin
					master_read = 1'b1;
					master_address = bias_addr;
					nextstate = master_waitrequest ? REQBIAS : RCVBIAS;
				end
				else begin
					nextstate = SETUP;
					master_address = 32'd0;
					master_read = 1'b0;
				end
			end
			RCVBIAS: begin
				getdata = 3'd1;
				slave_waitrequest = 1'd1;
				master_writedata = 32'd0;
				master_address = bias_addr;
				master_write = 1'b0;
				master_read = 1'b0;
				nextstate = master_readdatavalid ? REQWEIGHT : RCVBIAS;
			end
			REQWEIGHT: begin
				slave_waitrequest = 1'd1;
				master_write = 1'b0;
				master_writedata = 32'd0;
				getdata = 3'd0;
				if(count < length) begin
					master_read = 1'b1;
					master_address = weight_addr + (count << 2);
					nextstate = master_waitrequest ? REQWEIGHT : RCVWEIGHT;
				end
				else begin
					nextstate = RELU;
					master_address = 32'd0;
					master_read = 1'b0;
				end
			end
			RCVWEIGHT: begin
				getdata = 3'd2;
				slave_waitrequest = 1'd1;
				master_writedata = 32'd0;
				master_address = weight_addr + (count << 2);
				master_write = 1'b0;
				master_read = 1'b0;
				nextstate = master_readdatavalid ? REQINPUT : RCVWEIGHT;
			end
			REQINPUT: begin
				slave_waitrequest = 1'd1;
				master_write = 1'b0;
				master_writedata = 32'd0;
				getdata = 3'd0;
				master_read = 1'b1;
				master_address = inactivation_addr + (count << 2);
				nextstate = master_waitrequest ? REQINPUT : RCVINPUT;
			end
			RCVINPUT: begin
				getdata = 3'd3;
				slave_waitrequest = 1'd1;
				master_writedata = 32'd0;
				master_address = inactivation_addr + (count << 2);
				master_write = 1'b0;
				master_read = 1'b0;
				nextstate = master_readdatavalid ? CALC : RCVINPUT;
			end
			CALC: begin
				slave_waitrequest = 1'd1;
				master_address = 32'd0;
				master_write = 1'b0;
				getdata = 3'd4;
				master_read = 1'b0;
				master_writedata = 32'd0;
				nextstate = REQWEIGHT;
			end
			RELU: begin
				getdata = (relu[0] == 1'd1) ? 3'd6 : 3'd5;
				slave_waitrequest = 1'd1;
				master_writedata = 32'd0;
				master_write = 1'b0;
				master_read = 1'b0;
				master_address = 32'd0;
				nextstate = WRITEOUPUT;
			end
            WRITEOUPUT: begin
				slave_waitrequest = 1'd1;
				master_address = outactivation_addr;
				master_write = 1'b1;
				getdata = 3'd0;
				master_read = 1'b0;
				master_writedata = outactivation;
				nextstate = master_waitrequest ? WRITEOUPUT : SETUP;
			end
			default: begin
				getdata = 3'd0;
				slave_waitrequest = 1'b0;
				master_writedata = 32'd0;
				master_address = 32'd0;
				master_read = 1'd0;
				master_write = 1'd0;
			end	
		endcase
	end

endmodule: dnn
