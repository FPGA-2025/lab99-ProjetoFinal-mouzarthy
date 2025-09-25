module mux(
	input wire clk,
	input wire rstn,
	output [1:0] out
);

parameter MAX_COUNTER = 2'b11;

reg[1:0] mux_counter;

always @(posedge clk, negedge rstn) begin
	
	if(rstn == 0) begin
		mux_counter <= 2'b0;
	end
	else begin
		
		if(mux_counter < (MAX_COUNTER - 1'b1) ) 	mux_counter <= mux_counter + 1'b1;
		else mux_counter <= 2'b0;
		
	end

end

assign out = mux_counter;

endmodule 