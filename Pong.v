`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:02:33 06/24/2017 
// Design Name: 
// Module Name:    Pong 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module Pong(input CLOCK_50, 
				output [3:0] VGA_R, 
				output [3:0] VGA_G, 
				output [3:0] VGA_B, 
				output VGA_HS, 
				output VGA_VS, 
				input [9:0]SW, 
				input playerUp1,
				input playerDown1,
				input playerUp2,
				input playerDown2, 
				output [0:6]HEX3, 
				output [0:6]HEX2, 
				output [0:6]HEX1, 
				output [0:6]HEX0,
				output [0:6]out1,
				output [0:6]out2,
				output speaker
				);
	
	//Generate 25MHz clock for TV
	reg clk;
	reg clk5;

	always@(posedge CLOCK_50)
		begin
			clk <= ~clk;
		end

	reg [31:0] counter;
	always@(posedge clk)
		if(counter == 50000) 
			begin
				counter <= 0;
				clk5 <= ~clk5;
			end 
		else
			counter <= counter + 1;

	//Moving
	wire inMove1;
	wire inMove2;
	
	control ctrl(CLOCK50,playerUp1,playerDown1,playerUp2,playerDown2,inMove1,inMove2);
	
	//Scores
	reg [3:0] score;
	reg [3:0] score1;
	
	
	segments segm(CLOCK_50,score,score1,out1,out2);
	//Syncs with the monitor and provides us with x,y and when the display is active
	wire [9:0]x; 
	wire [9:0]y;
	VGA_Output (clk, VGA_HS, VGA_VS, display, x, y);

	//The ball it's actually a square 10:13 cause ratio is funny	
	wire [3:0]ball;
	reg [9:0]ballX;
	reg [9:0]ballY;
		
	assign ball = ((x-ballX)*(x-ballX) + (y-ballY)*(y-ballY) < 36)?4'b1111:4'b0;

	//Player one paddle
	wire [3:0] paddle;
	reg [9:0] paddleY;
	assign paddle = ((y>paddleY) && (y<paddleY+50) && (x>10) && (x<25))?4'b1111:4'b0;
		
	always@(posedge clk5)
		begin
			if(inMove1==1)
				if(~playerUp1 && paddleY<430)
					paddleY <= paddleY + 1;
				else if (~playerDown1 && |paddleY)
					paddleY <= paddleY - 1;
		end

	//Player two paddle	
	wire [3:0] paddle1;
	reg [9:0] paddleY1;
	assign paddle1 = ((y>paddleY1) && (y<paddleY1+50) && (x>615) && (x<630))?4'b1111:4'b0;		
		
	always@(posedge clk5)
		begin
			if(inMove2==1)
				if(~playerUp2 && paddleY1<430)
					paddleY1 <= paddleY1 + 1;
				else if (~playerDown2 && |paddleY1)
					paddleY1 <= paddleY1 - 1;
		end

	//v = velocity determines movment in x/y fliped in a bounce
	reg [1:0] v;
		always@(posedge clk5)
			begin
				if(~miss) 
					begin
						ballX <= v[0]?ballX - 1:ballX + 1;
						ballY <= v[1]?ballY - 1:ballY + 1;
					end 
				else if (SW[9])
					begin
						ballX <= 320;
						ballY <= 240;
					end
			end

	//Detect bounce and sound a miss
	reg bounceX;
	reg bounceY;
	reg miss;
	always@(posedge CLOCK_50)
		begin
			if(ballY == 0 && ~bounceY) 
				begin
					v[1] <= 0;
					bounceY <= 1;
				end 
			else if(ballY >=467 && ~bounceY) 
				begin
					v[1] <= 1;
					bounceY <= 1;
				end 
			else 
				bounceY <= 0;
		end

	
	always@(posedge clk5)
		begin
			if(ballX < 25 && ~bounceX && ballY+13>paddleY && ballY<paddleY+50) 
				begin
					v[0] <= 0;
					bounceX <= 1;
				end 
			else if(ballX > 615 && ~bounceX && ballY+13>paddleY1 && ballY<paddleY1+50) 
				begin
					v[0] <= 1;
					bounceX <= 1;
				end 
			else if(ballX > 630 && ~bounceX) 
				begin
					v[0] <= 1;
					bounceX <= 1;
					miss <= 1;
					score1 = score1 + 1;
				end 
			else if(ballX < 2 && ~bounceX) 
				begin
					v[0] <= 0;
					bounceX <= 1;
					miss <= 1;
					score = score + 1;
				end 
			else 
				begin
					bounceX <= 0;
					miss <= 0;
				end
		
		end		

	//central white line could also make border with this.
	wire [3:0] line;
	assign line = (x>318 && x<322 && y>10 && y<470)?4'b1111:4'b0;
	
	//Audio
	BG_Player bgp (.clk(clk), .speaker(speaker));

	//Send VGA signals white = 1111 which always wins in |	
	assign VGA_R = display?{SW[8:6],1'b0}|line|ball|paddle|paddle1:0;
	assign VGA_G = display?{SW[5:3],1'b0}|line|ball|paddle|paddle1:0;
	assign VGA_B = display?{SW[2:0],1'b0}|line|ball|paddle|paddle1:0;

	//Not needed but makes it a little nicer
	initial begin
		ballX = 320;
		ballY = 240;
		paddleY = 215;
		paddleY1 = 215;
	end

endmodule


module VGA_Output(iclk, oVGA_HS, oVGA_VS, oActive, oX, oY);
	input iclk;
	output oVGA_HS, oVGA_VS;
	output oActive;
	output [9:0] oX, oY;
	reg [9:0]x,y;

	assign oActive = ((y>34 && y<514) && (x>143 && x<783));
	assign oX = oActive?x-143:0;
	assign oY = oActive?y-34:0;
	wire line, frame;
	assign line = (x==799);
	assign frame = (y==524);
	always@(posedge iclk)
		if(line)
			x <= 0;
		else
			x <= x + 1;
	always@(posedge iclk)
		if (frame)
			y <= 0;
		else if (line)
			y <= y + 1;

	assign oVGA_HS = ~(x>0 && x<95);
	assign oVGA_VS = ~(y==0 || y==1);
endmodule

module b2seg(in, out);
	input [3:0]in;
	output [6:0]out;
	reg [0:6]out;
	
	always @(*)
	begin
		case (in)
			0: out = 7'b0000001;
			1: out = 7'b1001111;
			2: out = 7'b0010010;
			3: out = 7'b0000110;
			4: out = 7'b1001100;
			5: out = 7'b0100100;
			6: out = 7'b0100000;
			7: out = 7'b0001111;
			8: out = 7'b0000000;
			9: out = 7'b0001100;
			10: out = 7'b0001000;
			11: out = 7'b1100000;
			12: out = 7'b0110001;
			13: out = 7'b1000010;
			14: out = 7'b0110000;
			15: out = 7'b0111000;
			default: out = 7'b1111111;
		endcase
	end

endmodule

module bcd(in, out);
	input [4:0]in;
	output [7:0]out;
	
	wire [12:0]w0,w1,w2;
	assign w0 = in<<3;
	add3 (.in(w0), .out(w1));
	add3 (.in(w1<<1), .out(w2));
	assign out[7:0] = w2[11:4]; //Final shift [12:5]
endmodule

module add3(in, out);
	input [12:0]in;
	output [12:0]out;
	reg [12:0]out;
	
	always@(*)
	begin
		out = in;
		if(in[12:9]>4) out[12:9] = in[12:9] + 3;
		if(in[8:5]>4) out[8:5] = in[8:5] + 3;
	end
endmodule

module BG_Player(
	input clk,
	output reg speaker
);

reg [30:0] tone;
always @(posedge clk) tone <= tone+31'd1;

wire [7:0] fullnote;
music_ROM get_fullnote(.clk(clk), .address(tone[29:22]), .note(fullnote));

wire [2:0] octave;
wire [3:0] note;
divide_by12 get_octave_and_note(.numerator(fullnote[5:0]), .quotient(octave), .remainder(note));

reg [8:0] clkdivider;
always @*
case(note)
	 0: clkdivider = 9'd511;//A
	 1: clkdivider = 9'd482;// A#/Bb
	 2: clkdivider = 9'd455;//B
	 3: clkdivider = 9'd430;//C
	 4: clkdivider = 9'd405;// C#/Db
	 5: clkdivider = 9'd383;//D
	 6: clkdivider = 9'd361;// D#/Eb
	 7: clkdivider = 9'd341;//E
	 8: clkdivider = 9'd322;//F
	 9: clkdivider = 9'd303;// F#/Gb
	10: clkdivider = 9'd286;//G
	11: clkdivider = 9'd270;// G#/Ab
	default: clkdivider = 9'd0;
endcase

reg [8:0] counter_note;
reg [7:0] counter_octave;
always @(posedge clk) counter_note <= counter_note==0 ? clkdivider : counter_note-9'd1;
always @(posedge clk) if(counter_note==0) counter_octave <= counter_octave==0 ? 8'd255 >> octave : counter_octave-8'd1;
always @(posedge clk) if(counter_note==0 && counter_octave==0 && fullnote!=0 && tone[21:18]!=0) speaker <= ~speaker;
endmodule

/////////////////////////////////////////////////////
module divide_by12(
	input [5:0] numerator,  // value to be divided by 12
	output reg [2:0] quotient, 
	output [3:0] remainder
);

reg [1:0] remainder3to2;
always @(numerator[5:2])
case(numerator[5:2])
	 0: begin quotient=0; remainder3to2=0; end
	 1: begin quotient=0; remainder3to2=1; end
	 2: begin quotient=0; remainder3to2=2; end
	 3: begin quotient=1; remainder3to2=0; end
	 4: begin quotient=1; remainder3to2=1; end
	 5: begin quotient=1; remainder3to2=2; end
	 6: begin quotient=2; remainder3to2=0; end
	 7: begin quotient=2; remainder3to2=1; end
	 8: begin quotient=2; remainder3to2=2; end
	 9: begin quotient=3; remainder3to2=0; end
	10: begin quotient=3; remainder3to2=1; end
	11: begin quotient=3; remainder3to2=2; end
	12: begin quotient=4; remainder3to2=0; end
	13: begin quotient=4; remainder3to2=1; end
	14: begin quotient=4; remainder3to2=2; end
	15: begin quotient=5; remainder3to2=0; end
endcase

assign remainder[1:0] = numerator[1:0];  // the first 2 bits are copied through
assign remainder[3:2] = remainder3to2;  // and the last 2 bits come from the case statement
endmodule
/////////////////////////////////////////////////////


module music_ROM(
	input clk,
	input [7:0] address,
	output reg [7:0] note
);

always @(posedge clk)
case(address)
	  0: note<= 8'd25;
	  1: note<= 8'd27;
	  2: note<= 8'd27;
	  3: note<= 8'd25;
	  4: note<= 8'd22;
	  5: note<= 8'd22;
	  6: note<= 8'd30;
	  7: note<= 8'd30;
	  8: note<= 8'd27;
	  9: note<= 8'd27;
	 10: note<= 8'd25;
	 11: note<= 8'd25;
	 12: note<= 8'd25;
	 13: note<= 8'd25;
	 14: note<= 8'd25;
	 15: note<= 8'd25;
	 16: note<= 8'd25;
	 17: note<= 8'd27;
	 18: note<= 8'd25;
	 19: note<= 8'd27;
	 20: note<= 8'd25;
	 21: note<= 8'd25;
	 22: note<= 8'd30;
	 23: note<= 8'd30;
	 24: note<= 8'd29;
	 25: note<= 8'd29;
	 26: note<= 8'd29;
	 27: note<= 8'd29;
	 28: note<= 8'd29;
	 29: note<= 8'd29;
	 30: note<= 8'd29;
	 31: note<= 8'd29;
	 32: note<= 8'd23;
	 33: note<= 8'd25;
	 34: note<= 8'd25;
	 35: note<= 8'd23;
	 36: note<= 8'd20;
	 37: note<= 8'd20;
	 38: note<= 8'd29;
	 39: note<= 8'd29;
	 40: note<= 8'd27;
	 41: note<= 8'd27;
	 42: note<= 8'd25;
	 43: note<= 8'd25;
	 44: note<= 8'd25;
	 45: note<= 8'd25;
	 46: note<= 8'd25;
	 47: note<= 8'd25;
	 48: note<= 8'd25;
	 49: note<= 8'd27;
	 50: note<= 8'd25;
	 51: note<= 8'd27;
	 52: note<= 8'd25;
	 53: note<= 8'd25;
	 54: note<= 8'd27;
	 55: note<= 8'd27;
	 56: note<= 8'd22;
	 57: note<= 8'd22;
	 58: note<= 8'd22;
	 59: note<= 8'd22;
	 60: note<= 8'd22;
	 61: note<= 8'd22;
	 62: note<= 8'd22;
	 63: note<= 8'd22;
	 64: note<= 8'd25;
	 65: note<= 8'd27;
	 66: note<= 8'd27;
	 67: note<= 8'd25;
	 68: note<= 8'd22;
	 69: note<= 8'd22;
	 70: note<= 8'd30;
	 71: note<= 8'd30;
	 72: note<= 8'd27;
	 73: note<= 8'd27;
	 74: note<= 8'd25;
	 75: note<= 8'd25;
	 76: note<= 8'd25;
	 77: note<= 8'd25;
	 78: note<= 8'd25;
	 79: note<= 8'd25;
	 80: note<= 8'd25;
	 81: note<= 8'd27;
	 82: note<= 8'd25;
	 83: note<= 8'd27;
	 84: note<= 8'd25;
	 85: note<= 8'd25;
	 86: note<= 8'd30;
	 87: note<= 8'd30;
	 88: note<= 8'd29;
	 89: note<= 8'd29;
	 90: note<= 8'd29;
	 91: note<= 8'd29;
	 92: note<= 8'd29;
	 93: note<= 8'd29;
	 94: note<= 8'd29;
	 95: note<= 8'd29;
	 96: note<= 8'd23;
	 97: note<= 8'd25;
	 98: note<= 8'd25;
	 99: note<= 8'd23;
	100: note<= 8'd20;
	101: note<= 8'd20;
	102: note<= 8'd29;
	103: note<= 8'd29;
	104: note<= 8'd27;
	105: note<= 8'd27;
	106: note<= 8'd25;
	107: note<= 8'd25;
	108: note<= 8'd25;
	109: note<= 8'd25;
	110: note<= 8'd25;
	111: note<= 8'd25;
	112: note<= 8'd25;
	113: note<= 8'd27;
	114: note<= 8'd25;
	115: note<= 8'd27;
	116: note<= 8'd25;
	117: note<= 8'd25;
	118: note<= 8'd32;
	119: note<= 8'd32;
	120: note<= 8'd30;
	121: note<= 8'd30;
	122: note<= 8'd30;
	123: note<= 8'd30;
	124: note<= 8'd30;
	125: note<= 8'd30;
	126: note<= 8'd30;
	127: note<= 8'd30;
	128: note<= 8'd27;
	129: note<= 8'd27;
	130: note<= 8'd27;
	131: note<= 8'd27;
	132: note<= 8'd30;
	133: note<= 8'd30;
	134: note<= 8'd30;
	135: note<= 8'd27;
	136: note<= 8'd25;
	137: note<= 8'd25;
	138: note<= 8'd22;
	139: note<= 8'd22;
	140: note<= 8'd25;
	141: note<= 8'd25;
	142: note<= 8'd25;
	143: note<= 8'd25;
	144: note<= 8'd23;
	145: note<= 8'd23;
	146: note<= 8'd27;
	147: note<= 8'd27;
	148: note<= 8'd25;
	149: note<= 8'd25;
	150: note<= 8'd23;
	151: note<= 8'd23;
	152: note<= 8'd22;
	153: note<= 8'd22;
	154: note<= 8'd22;
	155: note<= 8'd22;
	156: note<= 8'd22;
	157: note<= 8'd22;
	158: note<= 8'd22;
	159: note<= 8'd22;
	160: note<= 8'd20;
	161: note<= 8'd20;
	162: note<= 8'd22;
	163: note<= 8'd22;
	164: note<= 8'd25;
	165: note<= 8'd25;
	166: note<= 8'd27;
	167: note<= 8'd27;
	168: note<= 8'd29;
	169: note<= 8'd29;
	170: note<= 8'd29;
	171: note<= 8'd29;
	172: note<= 8'd29;
	173: note<= 8'd29;
	174: note<= 8'd29;
	175: note<= 8'd29;
	176: note<= 8'd30;
	177: note<= 8'd30;
	178: note<= 8'd30;
	179: note<= 8'd30;
	180: note<= 8'd29;
	181: note<= 8'd29;
	182: note<= 8'd27;
	183: note<= 8'd27;
	184: note<= 8'd25;
	185: note<= 8'd25;
	186: note<= 8'd23;
	187: note<= 8'd20;
	188: note<= 8'd20;
	189: note<= 8'd20;
	190: note<= 8'd20;
	191: note<= 8'd20;
	192: note<= 8'd25;
	193: note<= 8'd27;
	194: note<= 8'd27;
	195: note<= 8'd25;
	196: note<= 8'd22;
	197: note<= 8'd22;
	198: note<= 8'd30;
	199: note<= 8'd30;
	200: note<= 8'd27;
	201: note<= 8'd27;
	202: note<= 8'd25;
	203: note<= 8'd25;
	204: note<= 8'd25;
	205: note<= 8'd25;
	206: note<= 8'd25;
	207: note<= 8'd25;
	208: note<= 8'd25;
	209: note<= 8'd27;
	210: note<= 8'd25;
	211: note<= 8'd27;
	212: note<= 8'd25;
	213: note<= 8'd25;
	214: note<= 8'd30;
	215: note<= 8'd30;
	216: note<= 8'd29;
	217: note<= 8'd29;
	218: note<= 8'd29;
	219: note<= 8'd29;
	220: note<= 8'd29;
	221: note<= 8'd29;
	222: note<= 8'd29;
	223: note<= 8'd29;
	224: note<= 8'd23;
	225: note<= 8'd25;
	226: note<= 8'd25;
	227: note<= 8'd23;
	228: note<= 8'd20;
	229: note<= 8'd20;
	230: note<= 8'd29;
	231: note<= 8'd29;
	232: note<= 8'd27;
	233: note<= 8'd27;
	234: note<= 8'd25;
	235: note<= 8'd25;
	236: note<= 8'd25;
	237: note<= 8'd25;
	238: note<= 8'd25;
	239: note<= 8'd25;
	240: note<= 8'd25;
	241: note<= 8'd0;
	242: note<= 8'd00;
	default: note <= 8'd0;
endcase
endmodule

module control(
    // 50MHz clock input
    input clk,
    // Input from reset button (active low)
    input playerU1,
    input playerD1,
    input playerU2,
    input playerD2,
    output reg moving1,
    output reg moving2
    );
    
always@(clk)
begin
  if(playerU1==1)
  begin
     moving1 = 1;
  end else if(playerD1==1)
  begin
     moving1 = 1;
  end else begin
     moving1 = 0;
  end
  
  if(playerU2==1)
  begin
     moving2 = 1;
  end else if(playerD2==1)
  begin
     moving2 = 1;
  end else begin
     moving2 = 0;
  end
end
endmodule

module segments(input clk,
    input[3:0] scoreP1,
    input[3:0] scoreP2,
    output reg[6:0] outP1,
    output reg[6:0] outP2
    );
	always @(posedge clk)
	begin
  //ABCDEFG
		case (scoreP1)
			0: outP1 = 7'b1111110;
			1: outP1 = 7'b0110000;
			2: outP1 = 7'b1101101;
			3: outP1 = 7'b1111001;
			4: outP1 = 7'b0110011;
			5: outP1 = 7'b1011011;
			6: outP1 = 7'b1011111;
			7: outP1 = 7'b1110000;
			8: outP1 = 7'b1111111;
			9: outP1 = 7'b1111011;
			default: outP1 = 7'b0000000;
		endcase
    case (scoreP2)
			0: outP2 = 7'b1111110;
			1: outP2 = 7'b0110000;
			2: outP2 = 7'b1101101;
			3: outP2 = 7'b1111001;
			4: outP2 = 7'b0110011;
			5: outP2 = 7'b1011011;
			6: outP2 = 7'b1011111;
			7: outP2 = 7'b1110000;
			8: outP2 = 7'b1111111;
			9: outP2 = 7'b1111011;
			default: outP2 = 7'b0000000;
		endcase
	end
endmodule
