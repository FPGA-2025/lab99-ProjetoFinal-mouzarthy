/*https://github.com/AmeerAbdelhadi/Binary-to-BCD-Converter
module int_to_bcd  
	#( parameter W = 16)  // input width
	( 
	input 		[W-1:0] bin   ,  // binary
	output reg [W+(W-4)/3:0] bcd   
	); // bcd {...,thousands,hundreds,tens,ones}

  integer i,j;

  always @(bin) begin
    for(i = 0; i <= W+(W-4)/3; i = i+1) bcd[i] = 0;     // initialize with zeros
    bcd[W-1:0] = bin;                                   // initialize with input vector
    for(i = 0; i <= W-4; i = i+1)                       // iterate on structure depth
      for(j = 0; j <= i/3; j = j+1)                     // iterate on structure width
        if (bcd[W-i+4*j -: 4] > 4)                      // if > 4
          bcd[W-i+4*j -: 4] = bcd[W-i+4*j -: 4] + 4'd3; // add 3
  end


endmodule 
*/

module bin2bcd
(	
//	i_start,
	i_binary,
	o_bcd
);
//input					i_start;
input 	[15:0] 	i_binary;
output 	[19:0] 	o_bcd;

reg 	[19:0] 	r_bcd = 20'b0;

integer i;

// double-dabble algorithm
//always @(posedge i_start)
always @(*)
	begin
		r_bcd = 20'b0;
		for(i = 0; i < 16; i = i+1)
		begin
			r_bcd = {r_bcd[18:0], i_binary[15-i]};
			if(i < 15 && r_bcd[3:0] > 4)
				r_bcd[3:0] = r_bcd[3:0] + 3;
			if(i < 15 && r_bcd[7:4] > 4)
				r_bcd[7:4] = r_bcd[7:4] + 3;
			if(i < 15 && r_bcd[11:8] > 4)
				r_bcd[11:8] = r_bcd[11:8] + 3;	
			if(i < 15 && r_bcd[15:12] > 4)
				r_bcd[15:12] = r_bcd[15:12] + 3;
			if(i < 15 && r_bcd[19:16] > 4)
				r_bcd[19:16] = r_bcd[19:16] + 3;
		end
	end

assign o_bcd = r_bcd;

endmodule