module bcd_to_7seg(
	input wire 			dot,
	input wire	[3:0] 	bcd,
	output 		[7:0] 	segments
);

reg[7:0] out;

//Sequencia E D C PONTO B A F G
/*
	 ---A---
	|		|
	F		B
	|		|
	 ---G---
	|		|	
	E		C
	|		|
	 ---D---	O	

*/

always @(*) begin

	case(bcd) 
		//			    7  	   6     5      4    3      2     1     0
		//			    E  	   D     C     DOT   B      A     F     G
		4'd0: out = { 1'b0, 1'b0, 1'b0, ~dot, 1'b0, 1'b0, 1'b0, 1'b1 }; // ok
		4'd1: out = { 1'b1, 1'b1, 1'b0, ~dot, 1'b0, 1'b1, 1'b1, 1'b1 }; // ok
		4'd2: out = { 1'b0, 1'b0, 1'b1, ~dot, 1'b0, 1'b0, 1'b1, 1'b0 }; // ok
		4'd3: out = { 1'b1, 1'b0, 1'b0, ~dot, 1'b0, 1'b0, 1'b1, 1'b0 }; // ok
		4'd4: out = { 1'b1, 1'b1, 1'b0, ~dot, 1'b0, 1'b1, 1'b0, 1'b0 };
		4'd5: out = { 1'b1, 1'b0, 1'b0, ~dot, 1'b1, 1'b0, 1'b0, 1'b0 };
		4'd6: out = { 1'b0, 1'b0, 1'b0, ~dot, 1'b1, 1'b0, 1'b0, 1'b0 };		
		4'd7: out = { 1'b1, 1'b1, 1'b0, ~dot, 1'b0, 1'b0, 1'b1, 1'b1 };		
		4'd8: out = { 1'b0, 1'b0, 1'b0, ~dot, 1'b0, 1'b0, 1'b0, 1'b0 };
		4'd9: out = { 1'b1, 1'b0, 1'b0, ~dot, 1'b0, 1'b0, 1'b0, 1'b0 };
		default: out = 8'b1111_1111;
	endcase

end

assign segments = out;

endmodule 