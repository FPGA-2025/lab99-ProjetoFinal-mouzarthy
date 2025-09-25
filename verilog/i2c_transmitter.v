module i2c_transmitter (
	input wire clk, rstn, start ,
	input wire [6:0] address, 
	input wire [7:0] data,
	input wire sda_in,
	input wire scl_in,
	output reg sda, 
	output reg scl,
	output reg finished, 
	output reg ack,
	
	input wire[7:0] register 
);

	reg [7:0] reg_Address, reg_Data, reg_Register;
	
	reg [3:0] currState, nextState;
	parameter [3:0] STATE_IDLE           = 4'b0000, 
					STATE_START           = 4'b0001, 
					STATE_PREPARE_ADDRESS = 4'b0010, 
					STATE_SENDING_ADDRESS = 4'b0011, 
					STATE_WAIT0           = 4'b0100,
					STATE_PREPARE_REG     = 4'b0101, 
					STATE_SENDING_REG     = 4'b0110,
					STATE_WAIT1			  = 4'b0111,
					STATE_PREPARE_DATA    = 4'b1000, 
					STATE_SENDING_DATA    = 4'b1001,
					STATE_STOP            = 4'b1010;
					
	reg [8:0] sb_reg_byte, sb_reg_byte_m1;
	reg sb_send_byte;
	reg [3:0] sb_counter;
	reg [1:0] sb_bit_counter;
	reg sb_byte_finished;
	reg sb_sda, sb_scl;
	
	
	always @(start, currState, sb_byte_finished) begin
		case (currState)
			STATE_IDLE: begin
				
				if (start) nextState = STATE_START;
				else nextState = STATE_IDLE;
			end
			
			STATE_START: nextState = STATE_PREPARE_ADDRESS;
			
			STATE_PREPARE_ADDRESS: nextState = STATE_SENDING_ADDRESS;					 
			STATE_SENDING_ADDRESS: if (sb_byte_finished) nextState = STATE_WAIT0;            //SE TERMINOU, AVAN?A
								else nextState = STATE_SENDING_ADDRESS;
			
			STATE_WAIT0: if(ack==0) nextState = STATE_STOP;
						else nextState = STATE_PREPARE_REG;	
			
			STATE_PREPARE_REG: nextState = STATE_SENDING_REG;
			STATE_SENDING_REG: if (sb_byte_finished) nextState = STATE_WAIT1;  //DECIDE SE VOLTA PARA O PREPARE BYTE OU SE AVAN?A
						  else nextState = STATE_SENDING_REG;
			
			STATE_WAIT1: nextState = STATE_PREPARE_DATA;	
			
			STATE_PREPARE_DATA: nextState = STATE_SENDING_DATA;
			STATE_SENDING_DATA: if (sb_byte_finished) nextState = STATE_STOP;  //DECIDE SE VOLTA PARA O PREPARE BYTE OU SE AVAN?A
						  else nextState = STATE_SENDING_DATA;
							  
			STATE_STOP: nextState = STATE_IDLE;
			
			default: nextState = STATE_IDLE;
		endcase
	end
	
	//Esse always tem que determinar:
	// sda, scl
	// send_byte (comando da m?quina que manda o byte)
	// reg_byte (byte que a m?quina que manda o byte vai mandar)
	//always @(currState, sb_sda, sb_scl, address, data)
	always @(currState, sb_sda, sb_scl, address, data, register) begin
		case (currState)
			STATE_IDLE: 
			begin
				sda = 1'b1;
				scl = 1'b1;
				sb_send_byte = 1'b0;
				finished = 1'b0;
			end
			STATE_START: 
			begin
				sda = 1'b0;
				scl = 1'b1;
				sb_send_byte = 1'b0;
				reg_Address = {address, 1'b0};
				reg_Data = data;
				reg_Register = register;
				finished = 1'b0;
			end
			STATE_PREPARE_ADDRESS: 
			begin
				sda = 1'b0;
				scl = 1'b0;  //NESSE ESTADO EU TENHO QUE PREPARAR O BYTE QUE EU VOU MANDAR
				sb_send_byte = 1'b1;
				finished = 1'b0;
				sb_reg_byte_m1 = {reg_Address , 1'b1};									
			end
			STATE_SENDING_ADDRESS: 
			begin
				//NESSE ESTADO QUEM MANDA ? A OUTRA M?QUINA
				sda = sb_sda;
				scl = sb_scl;
				sb_send_byte = 1'b1;
				finished = 1'b0;
			end
			
			
			STATE_WAIT0: 
			begin
				sda = 1'b0;
				scl = 1'b0;
				sb_send_byte = 1'b0;
				finished = 1'b0;
			end
			STATE_PREPARE_REG: 
			begin
				sda = 1'b0;
				scl = 1'b0;  //NESSE ESTADO EU TENHO QUE PREPARAR O BYTE QUE EU VOU MANDAR
				sb_send_byte = 1'b1;
				finished = 1'b0;
				sb_reg_byte_m1 = {reg_Register, 1'b1};
			end
			STATE_SENDING_REG: 
			begin
				//NESSE ESTADO QUEM MANDA ? A OUTRA M?QUINA
				sda = sb_sda;
				scl = sb_scl;
				sb_send_byte = 1'b1;
				finished = 1'b0;
			end
			
			
			STATE_WAIT1: 
			begin
				sda = 1'b0;
				scl = 1'b0;
				sb_send_byte = 1'b0;
				finished = 1'b0;
			end
			
			STATE_PREPARE_DATA: 
			begin
				sda = 1'b0;
				scl = 1'b0;  //NESSE ESTADO EU TENHO QUE PREPARAR O BYTE QUE EU VOU MANDAR
				sb_send_byte = 1'b1;
				finished = 1'b0;
				sb_reg_byte_m1 = {reg_Data, 1'b1};
			end
			STATE_SENDING_DATA: 
			begin
				//NESSE ESTADO QUEM MANDA ? A OUTRA M?QUINA
				sda = sb_sda;
				scl = sb_scl;
				sb_send_byte = 1'b1;
				finished = 1'b0;
			end
			
			STATE_STOP: 
			begin
				sda = 1'b0; 
				scl = 1'b1;
				sb_send_byte = 1'b0;
				finished = 1'b1;
			end
			
			default: 
			begin
				sda = 1'b1;
				scl = 1'b1;
				sb_send_byte = 1'b0;
				finished = 1'b0;
			end
		endcase
	end
	
	always @(negedge rstn, posedge clk) begin
		if (rstn == 0) currState <= STATE_IDLE;
		else currState <= nextState;
	end
		
	//SENDING_BYTE MACHINE
	//Uso: sb_reg_byte tem que estar escrito antes que sb_send_byte seja 1. 
	//     sb_reg_byte n?o pode ser modificado enquanto sb_send_byte for 1.
	//     sb_send_byte tem que ir para 0 no clk seguinte a sb_byte_finished = 1.
	
	
	
	
	always @(posedge clk)
	begin
	if (sb_send_byte)
		begin
			if (sb_counter == 0)
				begin
					sb_reg_byte <= sb_reg_byte_m1;
					sb_counter <= sb_counter + 1;	
					sb_scl <= 0;
					sb_sda <= 0;
				end
			else if (sb_counter == 10)
				begin
					sb_sda <= 0;
					sb_scl <= 0;
					sb_byte_finished <= 1;
				end
			else
				begin
					if (sb_bit_counter == 0)
						begin
							sb_scl <= 0;
							sb_sda <= sb_reg_byte[8];				
				
							sb_bit_counter <= 1;
						end
					else if (sb_bit_counter == 1)
						begin
							sb_scl <= 1;
							sb_sda <= sb_reg_byte[8];				
				
							sb_bit_counter <= 2;
							if (sb_counter == 9)
								ack <= !sda_in;								
						end
					else
						begin
							sb_scl <= 0;
							sb_sda <= sb_reg_byte[8];				
				
							//Rotaciona o sb_reg_byte
							sb_reg_byte[8] <= sb_reg_byte[7];
							sb_reg_byte[7] <= sb_reg_byte[6];
							sb_reg_byte[6] <= sb_reg_byte[5];
							sb_reg_byte[5] <= sb_reg_byte[4];
							sb_reg_byte[4] <= sb_reg_byte[3];
							sb_reg_byte[3] <= sb_reg_byte[2];
							sb_reg_byte[2] <= sb_reg_byte[1];
							sb_reg_byte[1] <= sb_reg_byte[0];
				
							sb_bit_counter <= 0;				
							sb_counter <= sb_counter + 1;				
					
						end
				end
		end
	else
		begin
			sb_byte_finished <= 0;
			sb_sda <= 0;
			sb_scl <= 0;
			sb_counter <= 0;
			sb_bit_counter <= 0;
			//sb_reg_byte <= 9'b110011001; //PARA DEBUG. Na hora de rodar o reg_byte ? escrito pela outra m?quina, antes do send_byte ativar.
		end
	end

endmodule