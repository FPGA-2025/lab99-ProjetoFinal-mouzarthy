module clock_divider (
	input wire cd_clk_in ,
	output reg cd_clk_out_1khz,
	output reg cd_clk_out_100khz
);

parameter CLK_1KHZ 		= 25000;
parameter CLK_100KHZ 	= 125;

reg [31:0] clk_divider_counter_1khz ;
reg [31:0] clk_divider_counter_100khz ;

initial begin
	clk_divider_counter_1khz 	= 32'h0;
	clk_divider_counter_100khz 	= 32'h0;
	cd_clk_out_1khz 			= 1'b0;
	cd_clk_out_100khz 			= 1'b0;
end

always @( posedge cd_clk_in ) begin
	if ( clk_divider_counter_1khz < CLK_1KHZ - 1) begin
		clk_divider_counter_1khz <= clk_divider_counter_1khz + 1'b1;
	end else begin
		clk_divider_counter_1khz <= 32'h0;
		cd_clk_out_1khz <= ~cd_clk_out_1khz;
	end
end

always @( posedge cd_clk_in ) begin
	if ( clk_divider_counter_100khz < CLK_100KHZ - 1) begin
		clk_divider_counter_100khz <= clk_divider_counter_100khz + 1'b1;
	end else begin
		clk_divider_counter_100khz <= 32'h0;
		cd_clk_out_100khz <= ~cd_clk_out_100khz;
	end
end

endmodule
