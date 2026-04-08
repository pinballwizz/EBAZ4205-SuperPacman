/****************************************************
    FPGA Druaga ( Custom I/O chip emulation part )

        Copyright (c) 2007 MiSTer-X

      Super Pacman Support
                (c) 2021 Jose Tejada, jotego

*****************************************************/
module IOCTRL( CLK, UPDATE, RESET, ENABLE, WR, ADRS, IN, OUT,
    STKTRG12,   // Joystick controls
    CSTART12,   // Start buttons 
    DIPSW,
    IsMOTOS,
    MODEL );
 input          CLK;
 input          UPDATE;
 input          RESET;
 input          ENABLE;
 input          WR;
 input  [5:0]   ADRS;
 input  [7:0]   IN;
 output [7:0]   OUT;

 input  [11:0]  STKTRG12;       // { STKTRG2[5:0], STKSTG1[5:0] }
 input  [2:0]   CSTART12;       // { COIN, START2P, START1P }
 input  [23:0]  DIPSW;          // { DSW5[3:0] DSW4[3:0] DSW3[3:0], DSW2[3:0], DSW1[3:0], DSW0[3:0] }

 output         IsMOTOS;
 input  [2:0]   MODEL;


reg     [3:0]   mema[0:15];
reg     [3:0]   memb[0:15];
reg     [3:0]   memc[0:31];
reg     [3:0]   outr;

reg     [7:0]   credits;
reg     [7:0]   credit_add, credit_sub;

reg     [9:0]   pSTKTRG12;
reg     [2:0]   pCSTART12;

reg             bUpdate;
reg             bIOMode;

parameter [2:0] SUPERPAC=3'd5;
parameter [2:0] GROBDA=3'd6;


assign  OUT = { 4'b1111, outr };
assign  IsMOTOS = bIOMode;

// Detect falling edges:
wire      [11:0]   iSTKTRG12 = ( STKTRG12 ^ pSTKTRG12 ) & STKTRG12;
wire      [ 2:0]   iCSTART12 = ( CSTART12 ^ pCSTART12 ) & CSTART12;

wire        [3:0]   CREDIT_ONES, CREDIT_TENS;
BCDCONV creditsBCD( credits, CREDIT_ONES, CREDIT_TENS );

always @ ( posedge CLK ) begin
    if ( ENABLE ) begin
        if ( ADRS[5] )  begin
            if ( WR ) memc[ADRS[4:0]] <= IN;
            outr <= memc[ADRS[4:0]];
        end else if ( ADRS[4] ) begin
            if ( WR ) memb[ADRS[3:0]] <= IN;
            outr <= memb[ADRS[3:0]];
        end else begin
            if ( WR ) mema[ADRS[3:0]] <= IN;
            outr <= mema[ADRS[3:0]];
        end
    end

    if ( RESET ) begin
        pCSTART12  <= 0;
        pSTKTRG12  <= 0;
        bUpdate    <= 0;
        bIOMode    <= 0;
        credits    <= 0;
    end else begin
        if ( UPDATE & (~bUpdate) ) begin
            if ( mema[4'h8] == 4'h8 || MODEL==SUPERPAC )
                bIOMode <= 1'b1;       // Is running "Motos" ? (or GROBDA?)

				// Grobda specific 58XX / 56XX combination
				if (MODEL==GROBDA) begin
//--------------------------------------------------------------------------------------------				
//	 `include "ioctrl_2.v"

		case ( mema[4'h8] )

		4'h1,4'h3: begin
			credit_add = 0;
			credit_sub = 0;

			if ( iCSTART12[2] & ( credits < 99 ) ) begin
				credit_add = 8'h01;
				credits = credits + 1;
			end
	
			if ( mema[4'h9] == 0 ) begin
				if ( ( credits >= 2 ) & iCSTART12[1] ) begin
					credit_sub = 8'h02;
					credits = credits - 2;
				end else if ( ( credits >= 1 ) & iCSTART12[0] ) begin
					credit_sub = 8'h01;
					credits = credits - 1;
				end
			end

			mema[4'h0] <= credit_add;
			mema[4'h1] <= credit_sub | {7'd0,CSTART12[0]};
			mema[4'h2] <= CREDIT_TENS;
			mema[4'h3] <= CREDIT_ONES;
			mema[4'h4] <= STKTRG12[3:0]; 
			mema[4'h5] <= { CSTART12[0], iCSTART12[0], STKTRG12[4], iSTKTRG12[4] };
			mema[4'h6] <= STKTRG12[9:6];				
			mema[4'h7] <= { CSTART12[1], iCSTART12[1], STKTRG12[10], iSTKTRG12[10] };
		end
	
		4'h4: begin
			mema[4'h0] <= 0;
			mema[4'h1] <= 0;
			mema[4'h2] <= 0;
			mema[4'h3] <= 0;
			mema[4'h4] <= 0;
			mema[4'h5] <= 0;
			mema[4'h6] <= { CSTART12[1], CSTART12[0], 2'b00 };
			mema[4'h7] <= { CSTART12[1], CSTART12[0], 2'b00 };
		end

		// grobda: 9-15 = 2 3 4 5 6 7 8, expects 2 = f and 6 = c
		4'h5: begin
			mema[4'h2] <= 4'hF; 
			mema[4'h6] <= 4'hC; 
		end

		default:;
	
		endcase


		case ( memb[4'h8] )
	
		4'h3: begin
			memb[4'h0] <= 0;
			memb[4'h1] <= 0;
			memb[4'h2] <= 0;
			memb[4'h3] <= 0;
			memb[4'h4] <= 0;
			memb[4'h5] <= 0;
			memb[4'h6] <= 0;
			memb[4'h7] <= 0;
		end
	
		4'h9: begin
			memb[4'h0] <= DIPSW[11: 8];										// (P0) DSW1 Mappy
			memb[4'h1] <= DIPSW[15:12];

			memb[4'h2] <= DIPSW[ 3: 0];										// (P1) DSW0
			memb[4'h4] <= DIPSW[ 7: 4];

			memb[4'h5] <= DIPSW[15:12];											// (P2) DSW1 Druaga/DigDug2
			
			memb[4'h6] <= {DIPSW[23:22],STKTRG12[11],STKTRG12[ 5]};	// testing, may not be needed!									//           IsMappy ? DIPSW[19:16] : DIPSW[11:8]

			memb[4'h7] <= DIPSW[19:16];	// (P3) DSW2

			memb[4'h3] <= 0;
		end

		// grobda: 9-15 = 2 3 4 5 6 7 8, expects 2 = f and 6 = c
		4'h8: begin
			memb[4'h0] <= 4'h6; 
			memb[4'h1] <= 4'h9; 
		end

		default:;

		endcase
//-------------------------------------------------------------------------------------------
				end
            else begin
					if ( bIOMode ) begin
//--------------------------------------------------------------------------------------------					
//`include "ioctrl_1.v"

	case ( mema[4'h8] )

		4'h1: begin
			mema[4'h0] <= { 3'd0, CSTART12[2] };
			mema[4'h1] <= STKTRG12[3:0];
			mema[4'h2] <= STKTRG12[9:6];
			mema[4'h3] <= { CSTART12[1], CSTART12[0], STKTRG12[10], STKTRG12[4] };
			mema[4'h4] <= STKTRG12[9:6];
			mema[4'h5] <= STKTRG12[9:6];
			mema[4'h6] <= STKTRG12[9:6];
			mema[4'h7] <= STKTRG12[9:6];
			mema[4'h9] <= 0;
		end

		// credit management
		4'h4: begin
			credit_add = 0;
			credit_sub = 0;

			if ( iCSTART12[2] & ( credits < 99 ) ) begin
				credit_add = 8'h01;
				credits = credits + 1;
			end

			if ( mema[4'h9] == 0 ) begin
				if ( ( credits >= 2 ) && iCSTART12[1] ) begin
					credit_sub = 8'h02;
					credits = credits - 2;
				end else if ( ( credits >= 1 ) && iCSTART12[0] ) begin
					credit_sub = 8'h01;
					credits = credits - 1;
				end
			end

			mema[4'h0] <= credit_add;
			mema[4'h1] <= credit_sub | {7'd0,CSTART12[0]};
			mema[4'h2] <= CREDIT_TENS;
			mema[4'h3] <= CREDIT_ONES;
			mema[4'h4] <= STKTRG12[3:0];
			mema[4'h5] <= { CSTART12[0], iCSTART12[0], STKTRG12[4], iSTKTRG12[4] };
			mema[4'h6] <= STKTRG12[9:6];
			mema[4'h7] <= { CSTART12[1], iCSTART12[1], STKTRG12[10], iSTKTRG12[10] };
		end

		4'h8: begin	// Boot up check, expected values by
			// the software (Super Pacman, Motos $69,  Phozon $1C)
			mema[4'h0] <= 4'h6;
			mema[4'h1] <= 4'h9;
		end

		default:;

	endcase


	case ( memb[4'h8] )

		4'h8: begin
			memb[4'h0] <= 4'h6;
			memb[4'h1] <= 4'h9;
		end

		// Pac'n Pal DIP switches
		4'h3: begin
			memb[4'h0] <= 4'h0;
			memb[4'h1] <= 4'h0;
			memb[4'h2] <= 4'h0;
			memb[4'h3] <= 4'h0;
			memb[4'h4] <= DIPSW[3:0];
			memb[4'h5] <= DIPSW[23:20];
			memb[4'h6] <= DIPSW[19:16];
			memb[4'h7] <= DIPSW[15:12];
		end
		// Motos and Super Pacman
		4'h9: begin
			memb[4'h0] <= DIPSW[19:16];     // superpacman
			memb[4'h1] <= DIPSW[23:20];     // superpacman
			memb[4'h2] <= DIPSW[3:0];       // motos
			memb[4'h3] <= DIPSW[3:0];       // superpacman
			memb[4'h4] <= DIPSW[7:4];       // motos & superpacman
			memb[4'h5] <= 4'h0;
			memb[4'h6] <= DIPSW[15:12];     // motos & superpacman
			memb[4'h7] <= 4'h0;
		end

		default:;

	endcase

//--------------------------------------------------------------------------------------------
					end
					else begin
//--------------------------------------------------------------------------------------------					
//`include "ioctrl_0.v"

		case ( mema[4'h8] )

		4'h1,4'h3: begin
			credit_add = 0;
			credit_sub = 0;

			if ( iCSTART12[2] & ( credits < 99 ) ) begin
				credit_add = 8'h01;
				credits = credits + 1;
			end
	
			if ( mema[4'h9] == 0 ) begin
				if ( ( credits >= 2 ) & iCSTART12[1] ) begin
					credit_sub = 8'h02;
					credits = credits - 2;
				end else if ( ( credits >= 1 ) & iCSTART12[0] ) begin
					credit_sub = 8'h01;
					credits = credits - 1;
				end
			end

			mema[4'h0] <= credit_add;
			mema[4'h1] <= credit_sub | {7'd0,CSTART12[0]};
			mema[4'h2] <= CREDIT_TENS;
			mema[4'h3] <= CREDIT_ONES;
			mema[4'h4] <= STKTRG12[3:0]; 
			mema[4'h5] <= { CSTART12[0], iCSTART12[0], STKTRG12[4], iSTKTRG12[4] };
			mema[4'h6] <= STKTRG12[9:6];				
			mema[4'h7] <= { CSTART12[1], iCSTART12[1], STKTRG12[10], iSTKTRG12[10] };
		end
	
		4'h4: begin
			mema[4'h0] <= 0;
			mema[4'h1] <= 0;
			mema[4'h2] <= 0;
			mema[4'h3] <= 0;
			mema[4'h4] <= 0;
			mema[4'h5] <= 0;
			mema[4'h6] <= { CSTART12[1], CSTART12[0], 2'b00 };
			mema[4'h7] <= { CSTART12[1], CSTART12[0], 2'b00 };
		end

		4'h5: begin
			mema[4'h0] <= 4'h0;
			mema[4'h1] <= 4'h8; 
			mema[4'h2] <= 4'h4; 
			mema[4'h3] <= 4'h6; 
			mema[4'h4] <= 4'hE; 
			mema[4'h5] <= 4'hD; 
			mema[4'h6] <= 4'h9; 
			mema[4'h7] <= 4'hD; 
		end

		default:;
	
		endcase


		case ( memb[4'h8] )
	
		4'h1,4'h3: begin
			memb[4'h0] <= 0;
			memb[4'h1] <= 0;
			memb[4'h2] <= 0;
			memb[4'h3] <= 0;
			memb[4'h4] <= 0;
			memb[4'h5] <= 0;
			memb[4'h6] <= 0;
			memb[4'h7] <= 0;
		end
	
		4'h4: begin
			memb[4'h0] <= DIPSW[11: 8];										// (P0) DSW1 Mappy
			memb[4'h1] <= DIPSW[15:12];

			memb[4'h2] <= DIPSW[ 3: 0];										// (P1) DSW0
			memb[4'h4] <= DIPSW[ 7: 4];

			memb[4'h5] <={DIPSW[15:14],STKTRG12[ 5],iSTKTRG12[ 5]};	// (P2) DSW1 Druaga/DigDug2
			memb[4'h6] <= DIPSW[23:20];										//           IsMappy ? DIPSW[19:16] : DIPSW[11:8]

			memb[4'h7] <={DIPSW[19:18],STKTRG12[11],iSTKTRG12[11]};	// (P3) DSW2

			memb[4'h3] <= 0;
		end

		4'h5: begin
			memb[4'h0] <= 4'h0;
			memb[4'h1] <= 4'h8; 
			memb[4'h2] <= 4'h4; 
			memb[4'h3] <= 4'h6; 
			memb[4'h4] <= 4'hE; 
			memb[4'h5] <= 4'hD; 
			memb[4'h6] <= 4'h9; 
			memb[4'h7] <= 4'hD; 
		end

		default:;

		endcase

//--------------------------------------------------------------------------------------------
					end
				end

            pCSTART12 <= CSTART12;
            pSTKTRG12 <= STKTRG12;
        end
        bUpdate <= UPDATE;
    end

end

endmodule



module add3(in,out);

input [3:0] in;
output [3:0] out;
reg [3:0] out;

always @ (in)
    case (in)
    4'b0000: out <= 4'b0000;
    4'b0001: out <= 4'b0001;
    4'b0010: out <= 4'b0010;
    4'b0011: out <= 4'b0011;
    4'b0100: out <= 4'b0100;
    4'b0101: out <= 4'b1000;
    4'b0110: out <= 4'b1001;
    4'b0111: out <= 4'b1010;
    4'b1000: out <= 4'b1011;
    4'b1001: out <= 4'b1100;
    default: out <= 4'b0000;
    endcase

endmodule


module BCDCONV(A,ONES,TENS);

input  [7:0] A;
output [3:0] ONES, TENS;
wire   [3:0] c1,c2,c3,c4,c5,c6,c7;
wire   [3:0] d1,d2,d3,d4,d5,d6,d7;

assign d1 = {1'b0,A[7:5]};
assign d2 = {c1[2:0],A[4]};
assign d3 = {c2[2:0],A[3]};
assign d4 = {c3[2:0],A[2]};
assign d5 = {c4[2:0],A[1]};
assign d6 = {1'b0,c1[3],c2[3],c3[3]};
assign d7 = {c6[2:0],c4[3]};

add3 m1(d1,c1);
add3 m2(d2,c2);
add3 m3(d3,c3);
add3 m4(d4,c4);
add3 m5(d5,c5);
add3 m6(d6,c6);
add3 m7(d7,c7);

assign ONES = {c5[2:0],A[0]};
assign TENS = {c7[2:0],c5[3]};

endmodule

