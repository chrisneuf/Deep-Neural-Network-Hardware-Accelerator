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

    enum {RESET, REQREAD, RCVREAD, WRITE, DONE} state, next_state;
    logic start, done, incrementCount, captureData;
    logic [31:0] dest, src, count, currIter, srcData;
    always_ff@(posedge clk, negedge rst_n) begin
        if(~rst_n) begin
            state <= RESET;
            start <= 1'b0;
            dest <= 0;
            src <= 0;
            count <= 0;
            currIter <= 0;
            srcData <= 0;
        end else if(slave_write) begin
            state <= next_state;
            case(slave_address)
                4'd0: begin
                    start <= 1'b1;
                end
                4'd1: begin
                    dest <= slave_writedata;
                end
                4'd2: begin
                    src <= slave_writedata;
                end
                4'd3: begin
                    count <= slave_writedata;
                end
            endcase
        end else if(done) begin
            state <= next_state;
            start = 1'b0;
            currIter <= 1'b0;
            srcData <= 0;
        end else begin
            start <= 1'b0;
            state <= next_state;
            if(incrementCount)
                currIter <= currIter + 1;
            if(captureData)
                srcData <= master_readdata;
        end
    end

    assign slave_readdata = 0; // always 0
    always_comb begin
        case(state)
            RESET: begin
                // slave
                slave_waitrequest = 1'b0;
                //master
                master_address = 0;
                master_read = 1'b0;
                master_write = 1'b0;
                master_writedata = 0;
                
                done = 1'b0;
                captureData = 1'b0;
                incrementCount = 1'b0;
                if(start && count == 0)
                    next_state = DONE;
                else
                    next_state = start ? REQREAD : RESET;
            end
            REQREAD: begin
                // slave
                slave_waitrequest = 1'b1;
                // master
                master_address = src + (currIter << 2);
                master_read = 1'b1;
                master_write = 1'b0;
                master_writedata = 0;
                
                done = 1'b0;
                captureData = 1'b0;
                incrementCount = 1'b0;
                next_state = master_waitrequest ? REQREAD : RCVREAD;
            end
            RCVREAD: begin
                // slave
                slave_waitrequest = 1'b1;
                // master
                master_address = src + (currIter << 2);
                master_read = 1'b0;
                master_write = 1'b0;
                master_writedata = 0;
                
                done = 1'b0;
                captureData = 1'b1;
                incrementCount = 1'b0;
                next_state = master_readdatavalid ? WRITE : RCVREAD;
            end
            WRITE: begin
                // slave
                slave_waitrequest = 1'b1;
                // master
                master_address = dest + (currIter << 2);
                master_read = 1'b0;
                master_write = 1'b1;
                master_writedata = srcData;

                done = 1'b0;
                captureData = 1'b0;
                if(currIter + 1 == count && ~master_waitrequest) begin
                    next_state = DONE;
                    incrementCount = 1'b0;
                end else if(~master_waitrequest) begin
                    next_state = REQREAD;
                    incrementCount = 1'b1;
                end else begin
                    next_state = WRITE;
                    incrementCount = 1'b0;
                end
            end
            DONE: begin
                // slave
                slave_waitrequest = 1'b0;
                //master
                master_address = 0;
                master_read = 1'b0;
                master_write = 1'b0;
                master_writedata = 0;
                
                done = 1'b1;
                captureData = 1'b0;
                incrementCount = 1'b0;
                if(start && count == 0)
                    next_state = DONE;
                else
                    next_state = start ? REQREAD : DONE;
            end
            default: begin
                // slave
                slave_waitrequest = 1'b0;
                //master
                master_address = 0;
                master_read = 1'b0;
                master_write = 1'b0;
                master_writedata = 0;
                captureData = 1'b0;
                incrementCount = 1'b0;
                next_state = RESET;
                done = 1'b0;
            end
        endcase
    end

endmodule: wordcopy