module top(
	input wire fastclk,
	input wire rstn,
	
	inout wire scl,
	inout wire sda,
	
	output [7:0]segment_out,
	output [2:0]segment_enable
);

wire slowclk_1khz, slowclk_100khz;
wire[19:0] bcd;
wire[15:0] temp_bin;

clock_divider clk(
	.cd_clk_in(fastclk),
	.cd_clk_out_1khz(slowclk_1khz),
	.cd_clk_out_100khz(slowclk_100khz)
);


bmp_280 tmp(
	.clk(slowclk_100khz),
	.rstn(rstn),
	.sda(sda),
	.scl(scl),
	.busy(),
	.temperature(temp_bin)
	//.pressure() 
);

bin2bcd conv
(	
	.i_binary(temp_bin),
	.o_bcd(bcd)
);

display segments(
	.clk(slowclk_1khz),
	.rstn(rstn),
	.digit1(bcd[15:12]),
	.digit2(bcd[11:8]),
	.digit3(bcd[7:4]),
	
	.sement_out(segment_out),
	.segment_en(segment_enable)
);

endmodule 