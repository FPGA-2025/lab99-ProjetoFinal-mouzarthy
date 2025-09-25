module display(
	input wire clk,
	input wire rstn,
	input wire[3:0] digit1,
	input wire[3:0] digit2,
	input wire[3:0] digit3,
	
	output [7:0] sement_out,
	output [2:0] segment_en
);

reg[2:0] 	enable;
wire[1:0] 	mux_counter;
reg [3:0] 	digit;
reg 		dot;

bcd_to_7seg bcd(
	.dot(dot),
	.bcd(digit),
	.segments(sement_out)
);

mux mx(
	.clk(clk),
	.rstn(rstn),
	.out(mux_counter)
);

always @(*) begin
		
	if(rstn == 0) begin
		digit 	= 4'b1111;
		enable 	= 3'b111;
		dot 	= 1'b0;
	end
	else begin
		
		case(mux_counter)
			
			2'b00: begin
				digit 	= digit1;
				enable 	= 3'b110;
				dot 	= 1'b0;
			end
			
			2'b01: begin
				digit 	= digit2;
				enable 	= 3'b101;
				dot 	= 1'b1;
			end
			
			2'b10: begin
				digit 	= digit3;
				enable 	= 3'b011;
				dot 	= 1'b0;
			end
			
			default begin
				digit 	= 4'b1111;
				enable 	= 3'b111;
				dot 	= 1'b0;
			end
		endcase
	end
end

assign segment_en = enable;

endmodule 