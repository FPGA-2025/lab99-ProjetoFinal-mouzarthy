module bmp_280(
	input wire clk,
	input wire rstn,
	
	inout wire sda,
	inout wire scl,

	output reg busy, // trocar para leitura ok
	output reg [15:0] temperature
	//output reg signed [31:0] pressure 
);

//address 0x76 
localparam ADDR 				= 7'h76;

// hardware registers
localparam REG_CONFIG 			= 8'hF5; //(0xF5)
localparam REG_CTRL_MEAS 		= 8'hF4; //(0xF4)
localparam REG_RESET			= 8'hE0; //(0xE0)

localparam REG_TEMP_XLSB 		= 8'hFC; //(0xFC)
localparam REG_TEMP_LSB 		= 8'hFB; //(0xFB)
localparam REG_TEMP_MSB 		= 8'hFA; //(0xFA)

localparam REG_PRESSURE_XLSB 	= 8'hF9; //(0xF9)
localparam REG_PRESSURE_LSB 	= 8'hF8; //(0xF8)
localparam REG_PRESSURE_MSB 	= 8'hF7; //(0xF7)

// calibration registers
localparam REG_DIG_T1_LSB 		= 8'h88; //(0x88)
localparam REG_DIG_T1_MSB 		= 8'h89; //(0x89)
localparam REG_DIG_T2_LSB 		= 8'h8A; //(0x8A)
localparam REG_DIG_T2_MSB 		= 8'h8B; //(0x8B)
localparam REG_DIG_T3_LSB 		= 8'h8C; //(0x8C)
localparam REG_DIG_T3_MSB 		= 8'h8D; //(0x8D)
localparam REG_DIG_P1_LSB 		= 8'h8E; //(0x8E)
localparam REG_DIG_P1_MSB 		= 8'h8F; //(0x8F)
localparam REG_DIG_P2_LSB 		= 8'h90; //(0x90)
localparam REG_DIG_P2_MSB 		= 8'h91; //(0x91)
localparam REG_DIG_P3_LSB 		= 8'h92; //(0x92)
localparam REG_DIG_P3_MSB 		= 8'h93; //(0x93)
localparam REG_DIG_P4_LSB 		= 8'h94; //(0x94)
localparam REG_DIG_P4_MSB 		= 8'h95; //(0x95)
localparam REG_DIG_P5_LSB 		= 8'h96; //(0x96)
localparam REG_DIG_P5_MSB 		= 8'h97; //(0x97)
localparam REG_DIG_P6_LSB 		= 8'h98; //(0x98)
localparam REG_DIG_P6_MSB 		= 8'h99; //(0x99)
localparam REG_DIG_P7_LSB 		= 8'h9A; //(0x9A)
localparam REG_DIG_P7_MSB 		= 8'h9B; //(0x9B)
localparam REG_DIG_P8_LSB 		= 8'h9C; //(0x9C)
localparam REG_DIG_P8_MSB 		= 8'h9D; //(0x9D)
localparam REG_DIG_P9_LSB 		= 8'h9E; //(0x9E)
localparam REG_DIG_P9_MSB 		= 8'h9F; //(0x9F)

//dig_t1,dig_p1,.  fine_temp,fine_press, 
reg [15:0] dig_t1, dig_p1;
reg signed [15:0] dig_t2, dig_t3, dig_p2, dig_p3, dig_p4, dig_p5, dig_p6, dig_p7, dig_p8, dig_p9;
reg signed [31:0] raw_temp, raw_pressure, var1, var2;

/*ESTADOS DA MAQUINA*/
reg[7:0] STATE_IDLE		= 8'd0,
 STATE_CONFIG				= 8'd1,
 STATE_CLR_MEANS			= 8'd2,

 STATE_REG_DIG_T1_LSB 		= 8'd3,
 STATE_REG_DIG_T1_MSB 		= 8'd4,
 STATE_REG_DIG_T2_LSB 		= 8'd5,
 STATE_REG_DIG_T2_MSB 		= 8'd6,
 STATE_REG_DIG_T3_LSB 		= 8'd7,
 STATE_REG_DIG_T3_MSB 		= 8'd8,
 STATE_REG_DIG_P1_LSB 		= 8'd9,
 STATE_REG_DIG_P1_MSB 		= 8'd10,
 STATE_REG_DIG_P2_LSB 		= 8'd11,
 STATE_REG_DIG_P2_MSB 		= 8'd12,
 STATE_REG_DIG_P3_LSB 		= 8'd13,
 STATE_REG_DIG_P3_MSB 		= 8'd14,
 STATE_REG_DIG_P4_LSB 		= 8'd15,
 STATE_REG_DIG_P4_MSB 		= 8'd16,
 STATE_REG_DIG_P5_LSB 		= 8'd17,
 STATE_REG_DIG_P5_MSB 		= 8'd18,
 STATE_REG_DIG_P6_LSB 		= 8'd19,
 STATE_REG_DIG_P6_MSB 		= 8'd20,
 STATE_REG_DIG_P7_LSB 		= 8'd21,
 STATE_REG_DIG_P7_MSB 		= 8'd22,
 STATE_REG_DIG_P8_LSB 		= 8'd23,
 STATE_REG_DIG_P8_MSB 		= 8'd24,
 STATE_REG_DIG_P9_LSB 		= 8'd25,
 STATE_REG_DIG_P9_MSB 		= 8'd26,

 STATE_READ_RAW_PRESSURE_MSB 	= 8'd27,
 STATE_READ_RAW_PRESSURE_LSB	= 8'd28,
 STATE_READ_RAW_PRESSURE_XLSB 	= 8'd29,
 STATE_READ_RAW_TEMP_MSB		= 8'd30,
 STATE_READ_RAW_TEMP_LSB		= 8'd31,
 STATE_READ_RAW_TEMP_XLSB		= 8'd32,

 STATE_CONVERT_TEMPERATURE 		= 8'd33,
 STATE_CONVERT_PRESSURE 		= 8'd34,
 STATE_WAIT						= 8'd35;

reg [31:0] counter_delay;

reg [7:0] data_out, register;
reg [6:0] address;
wire[7:0] data_in;

reg [7:0] currState, nextState;

reg start_tx, start_rx;
wire finished, finished_tx, finished_rx;
wire tx_sda, tx_scl, rx_sda, rx_scl;
wire in_sda, in_scl;

i2c_transmitter tx(
		.clk(clk),
		.rstn(rstn),
		.start(start_tx),
		.address(address),
		.data(data_out),
		.sda_in(in_sda),
		.scl_in(in_scl),
		.sda(tx_sda),
		.scl(tx_scl),
		.finished(finished_tx),
		.ack(),
		.register(register)
	);

i2c_receiver rx (
		.clk(clk),
		.rstn(rstn),
		.start(start_rx),
		.address(address),
		.data(data_in),
		.sda_in(in_sda),
		.scl_in(in_scl),
		.sda(rx_sda),
		.scl(rx_scl),
		.finished(finished_rx),
		.ack(),
		.register(register)
	);

assign sda 		= (tx_sda & rx_sda) ? 1'bz : 1'b0;
assign scl 		= (tx_scl & rx_scl) ? 1'bz : 1'b0;
assign in_sda 	= sda;
assign in_scl 	= scl;

assign finished = (finished_tx | finished_rx);

always @(currState, finished, counter_delay) begin
	
	case(currState)		
		STATE_IDLE: nextState = STATE_CONFIG;
					//else nextState = STATE_IDLE;
		
		STATE_CONFIG: if(finished) nextState = STATE_CLR_MEANS;
						else  nextState = STATE_CONFIG;
		
		STATE_CLR_MEANS: if(finished) nextState = STATE_REG_DIG_T1_LSB;
							else  nextState = STATE_CLR_MEANS;

		STATE_REG_DIG_T1_LSB: if(finished) nextState = STATE_REG_DIG_T1_MSB;
								else  nextState = STATE_REG_DIG_T1_LSB;

		STATE_REG_DIG_T1_MSB: if(finished) nextState = STATE_REG_DIG_T2_LSB ;
								else  nextState = STATE_REG_DIG_T1_MSB;

		STATE_REG_DIG_T2_LSB: if(finished) nextState = STATE_REG_DIG_T2_MSB;
								else  nextState = STATE_REG_DIG_T2_LSB;
					
		STATE_REG_DIG_T2_MSB: if(finished) nextState = STATE_REG_DIG_T3_LSB;
								else  nextState = STATE_REG_DIG_T2_MSB;

		STATE_REG_DIG_T3_LSB: if(finished) nextState = STATE_REG_DIG_T3_MSB;
								else  nextState = STATE_REG_DIG_T3_LSB;

		STATE_REG_DIG_T3_MSB: if(finished) nextState = STATE_REG_DIG_P1_LSB;
								else  nextState = STATE_REG_DIG_T3_MSB;

		STATE_REG_DIG_P1_LSB: if(finished) nextState = STATE_REG_DIG_P1_MSB;
								else  nextState = STATE_REG_DIG_P1_LSB;

		STATE_REG_DIG_P1_MSB: if(finished) nextState = STATE_REG_DIG_P2_LSB;
								else  nextState = STATE_REG_DIG_P1_MSB;

		STATE_REG_DIG_P2_LSB: if(finished) nextState = STATE_REG_DIG_P2_MSB;
								else  nextState = STATE_REG_DIG_P2_LSB;

		STATE_REG_DIG_P2_MSB: if(finished) nextState = STATE_REG_DIG_P3_LSB;
								else  nextState = STATE_REG_DIG_P2_MSB;

		STATE_REG_DIG_P3_LSB: if(finished) nextState = STATE_REG_DIG_P3_MSB;
								else  nextState = STATE_REG_DIG_P3_LSB;

		STATE_REG_DIG_P3_MSB: if(finished) nextState = STATE_REG_DIG_P4_LSB;
								else  nextState = STATE_REG_DIG_P3_MSB;

		STATE_REG_DIG_P4_LSB: if(finished) nextState = STATE_REG_DIG_P4_MSB;
								else  nextState = STATE_REG_DIG_P4_LSB;

		STATE_REG_DIG_P4_MSB: if(finished) nextState = STATE_REG_DIG_P5_LSB;
								else  nextState = STATE_REG_DIG_P4_MSB;

		STATE_REG_DIG_P5_LSB: if(finished) nextState = STATE_REG_DIG_P5_MSB;
								else  nextState = STATE_REG_DIG_P5_LSB;

		STATE_REG_DIG_P5_MSB: if(finished) nextState = STATE_REG_DIG_P6_LSB;
								else  nextState = STATE_REG_DIG_P5_MSB;

		STATE_REG_DIG_P6_LSB: if(finished) nextState = STATE_REG_DIG_P6_MSB;
								else  nextState = STATE_REG_DIG_P6_LSB;

		STATE_REG_DIG_P6_MSB: if(finished) nextState = STATE_REG_DIG_P7_LSB;
								else  nextState = STATE_REG_DIG_P6_MSB;

		STATE_REG_DIG_P7_LSB: if(finished) nextState = STATE_REG_DIG_P7_MSB;
								else  nextState = STATE_REG_DIG_P7_LSB;

		STATE_REG_DIG_P7_MSB: if(finished) nextState = STATE_REG_DIG_P8_LSB;
								else  nextState = STATE_REG_DIG_P7_MSB;

		STATE_REG_DIG_P8_LSB: if(finished) nextState = STATE_REG_DIG_P8_MSB;
								else  nextState = STATE_REG_DIG_P8_LSB;

		STATE_REG_DIG_P8_MSB: if(finished) nextState = STATE_REG_DIG_P9_LSB;
								else  nextState = STATE_REG_DIG_P8_MSB;

		STATE_REG_DIG_P9_LSB: if(finished) nextState = STATE_REG_DIG_P9_MSB;
								else  nextState = STATE_REG_DIG_P9_LSB;
					
		STATE_REG_DIG_P9_MSB: if(finished) nextState = STATE_READ_RAW_PRESSURE_MSB; // MUDOU AQUI
								else  nextState = STATE_REG_DIG_P9_MSB;

		STATE_READ_RAW_PRESSURE_MSB: if(finished) nextState = STATE_READ_RAW_PRESSURE_LSB;
										else  nextState = STATE_READ_RAW_PRESSURE_MSB;
		
		STATE_READ_RAW_PRESSURE_LSB: if(finished) nextState = STATE_READ_RAW_PRESSURE_XLSB;
										else  nextState = STATE_READ_RAW_PRESSURE_LSB;

		STATE_READ_RAW_PRESSURE_XLSB: if(finished) nextState = STATE_READ_RAW_TEMP_MSB;
										else  nextState = STATE_READ_RAW_PRESSURE_XLSB;

		STATE_READ_RAW_TEMP_MSB:  if(finished) nextState = STATE_READ_RAW_TEMP_LSB;
									else  nextState = STATE_READ_RAW_TEMP_MSB;

		STATE_READ_RAW_TEMP_LSB:  if(finished) nextState = STATE_READ_RAW_TEMP_XLSB;
									else  nextState = STATE_READ_RAW_TEMP_LSB;

		STATE_READ_RAW_TEMP_XLSB:  if(finished) nextState = STATE_CONVERT_TEMPERATURE;
									else  nextState = STATE_READ_RAW_TEMP_XLSB;
		
		STATE_CONVERT_TEMPERATURE: nextState = STATE_CONVERT_PRESSURE;
					
		STATE_CONVERT_PRESSURE: nextState = STATE_WAIT;
		
		STATE_WAIT: if(counter_delay == 32'd500000) nextState = STATE_READ_RAW_PRESSURE_MSB;
					else nextState = STATE_WAIT;
/*						
		STATE_WAIT: if(timer_done == 1) nextState = STATE_READ_RAW_PRESSURE_MSB;
					else nextState = STATE_WAIT;
*/		
		default: nextState = STATE_IDLE;
		
	endcase
	
end

always @(currState) begin
	
	case(currState)	
		STATE_IDLE: begin
			raw_temp 		<= 32'b0;
			//raw_pressure 	<= 32'b0;
			data_out 		<= 8'b0;
			address			<= 7'b0;
			register		<= 8'b0;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b0;
			busy			<= 1'b0;
			//temperature		<= 32'b0;
			//pressure		<= 32'b0;
		end
		
		STATE_CONFIG: begin
			address		<= ADDR;
			register	<= REG_CONFIG;
			data_out 	<= 8'b1001_0100;
			start_tx 	<= 1'b1;
			start_rx 	<= 1'b0;
			
			busy		<= 1'b1;
		end
		
		STATE_CLR_MEANS:begin
			address		<= ADDR;
			register	<= REG_CTRL_MEAS;
			data_out 	<= 8'b0010_1111;
			start_tx 	<= 1'b1;
			start_rx 	<= 1'b0;
		end
		
		STATE_REG_DIG_T1_LSB: begin
			address			<= ADDR;
			register		<= REG_DIG_T1_LSB;
			dig_t1[7:0] 	<= data_in;

			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_T1_MSB: begin
			address			<= ADDR;
			register		<= REG_DIG_T1_MSB;
			dig_t1[15:8] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_T2_LSB: begin
			address			<= ADDR;
			register		<= REG_DIG_T2_LSB;
			dig_t2[7:0] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_T2_MSB: begin
			address			<= ADDR;
			register		<= REG_DIG_T2_MSB;
			dig_t2[15:8] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_T3_LSB: begin
			address			<= ADDR;
			register		<= REG_DIG_T3_LSB;
			dig_t3[7:0] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_T3_MSB: begin
			address			<= ADDR;
			register		<= REG_DIG_T3_MSB;
			dig_t3[15:8] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P1_LSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P1_LSB;
			dig_p1[7:0] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P1_MSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P1_MSB;
			dig_p1[15:8] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P2_LSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P2_LSB;
			dig_p2[7:0] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P2_MSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P2_MSB;
			dig_p2[15:8]	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P3_LSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P3_LSB;
			dig_p3[7:0] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P3_MSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P3_MSB;
			dig_p3[15:8] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P4_LSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P4_LSB;
			dig_p4[7:0] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P4_MSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P4_MSB;
			dig_p4[15:8] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P5_LSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P5_LSB;
			dig_p5[7:0] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P5_MSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P5_MSB;
			dig_p5[15:8] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P6_LSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P6_LSB;
			dig_p6[7:0] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P6_MSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P6_MSB;
			dig_p6[15:8] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P7_LSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P7_LSB;
			dig_p7[7:0] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P7_MSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P7_MSB;
			dig_p7[15:8] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P8_LSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P8_LSB;
			dig_p8[7:0] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P8_MSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P8_MSB;
			dig_p8[15:8] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_REG_DIG_P9_LSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P9_LSB;
			dig_p9[7:0] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end
		
		STATE_REG_DIG_P9_MSB: begin
			address			<= ADDR;
			register		<= REG_DIG_P9_MSB;
			dig_p9[15:8] 	<= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

// TRABALHAR DAQUI PARA BAIXO
		STATE_READ_RAW_PRESSURE_MSB: begin
			address				<= ADDR;
			register			<= REG_PRESSURE_MSB;
			raw_pressure[19:12]<= data_in;
			start_tx 			<= 1'b0;
			start_rx 			<= 1'b1;
			
			busy				<= 1'b1;
//			timer_start			<= 1'b0;
		end

		STATE_READ_RAW_PRESSURE_LSB: begin
			address				<= ADDR;
			register			<= REG_PRESSURE_LSB;
			raw_pressure[11:4] <= data_in;
			start_tx 			<= 1'b0;
			start_rx 			<= 1'b1;
		end

		STATE_READ_RAW_PRESSURE_XLSB: begin
			address				<= ADDR;
			register			<= REG_PRESSURE_XLSB;
			raw_pressure[3:0] 	<= data_in[7:4];
			start_tx 			<= 1'b0;
			start_rx 			<= 1'b1;
		end

		STATE_READ_RAW_TEMP_MSB: begin
			address			<= ADDR;
			register		<= REG_TEMP_MSB;
			raw_temp[19:12] <= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_READ_RAW_TEMP_LSB: begin
			address			<= ADDR;
			register		<= REG_TEMP_LSB;
			raw_temp[11:4] <= data_in;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_READ_RAW_TEMP_XLSB: begin
			address			<= ADDR;
			register		<= REG_TEMP_XLSB;
			raw_temp[3:0] 	<= data_in[7:4];
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b1;
		end

		STATE_CONVERT_TEMPERATURE:begin

			//var1 		<= (((raw_temp >> 3) - (dig_t1 << 1)) * dig_t2) >> 11;
			//var2 		<= (((((raw_temp >> 4) - dig_t1) * ((raw_temp >> 4) - dig_t1)) >> 12) * dig_t3) >> 14; 
			
			var1 <= ( ( ( (raw_temp >> 3) - ( dig_t1 << 1 ) ) ) * ( dig_t2 ) ) >> 11;
			var2 <= ( ( ( ( ( raw_temp >> 4 ) - ( dig_t1 ) ) * ( ( raw_temp >> 4 ) - 
            ( dig_t1 ) ) ) >> 12 ) * ( dig_t3 ) ) >> 14;
			
			//fine_temp 	<= var1 + var2;
			
			temperature <= ((((var1 + var2) * 5) + 128) >> 8) - 16'd1000;

			start_tx 		<= 1'b0;
			start_rx 		<= 1'b0;
		end
		
		STATE_CONVERT_PRESSURE:begin

			start_tx 		<= 1'b0;
			start_rx 		<= 1'b0;
		end

		STATE_WAIT: begin
			busy			<= 1'b0;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b0;
		end
		
		default:begin
			raw_temp 		<= 32'b0;
			raw_pressure 	<= 32'b0;
			data_out 		<= 8'b0;
			address			<= 7'b0;
			register		<= 8'b0;
			start_tx 		<= 1'b0;
			start_rx 		<= 1'b0;
			busy			<= 1'b0;
		end
		
	endcase
	
end


always @(negedge rstn, posedge clk) begin
	if (rstn == 0) begin 
		currState <= STATE_IDLE;
		counter_delay <= 32'b0;
	end
	else begin
		currState <= nextState;
		
		if(nextState == STATE_WAIT) counter_delay <= counter_delay + 1;
		else counter_delay <= 32'b0;
	end
end

endmodule 