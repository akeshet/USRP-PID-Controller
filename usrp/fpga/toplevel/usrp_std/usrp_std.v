// -*- verilog -*-
//
//  USRP - Universal Software Radio Peripheral
//
//  Copyright (C) 2003,2004 Matt Ettus
//
//  This program is free software; you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation; either version 2 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program; if not, write to the Free Software
//  Foundation, Inc., 51 Franklin Street, Boston, MA  02110-1301  USA
//

// Top level module for a full setup with DUCs and DDCs

// Define DEBUG_OWNS_IO_PINS if we're using the daughterboard i/o pins
// for debugging info.  NB, This can kill the m'board and/or d'board if you
// have anything except basic d'boards installed.

// Uncomment the following to include optional circuitry

`include "config.vh"
`include "../../../firmware/include/fpga_regs_common.v"
`include "../../../firmware/include/fpga_regs_standard.v"



/*
  
  This is the top level module of Aviv's digital
  yellow-laser lock controller. It is a modification of the
  original top level module for the USRP. The entirety of the 
  original code is commented out, after the new code.
  
  */


module usrp_std
(output MYSTERY_SIGNAL,
 input master_clk,
 input SCLK,
 input SDI,
 inout SDO,
 input SEN_FPGA,

 input FX2_1,
 output FX2_2,
 output FX2_3,
 
 input wire signed [11:0] rx_a_a,
 input wire signed [11:0] rx_b_a,
 input wire signed [11:0] rx_a_b,
 input wire signed [11:0] rx_b_b,

 output wire [13:0] tx_a,
 output wire [13:0] tx_b,

 output wire TXSYNC_A,
 output wire TXSYNC_B,
 
  // USB interface
 input usbclk,
 input wire [2:0] usbctl,
 output wire [1:0] usbrdy,
 inout [15:0] usbdata,  // NB Careful, inout

 // These are the general purpose i/o's that go to the daughterboard slots
 inout wire [15:0] io_tx_a,
 inout wire [15:0] io_tx_b,
 inout wire [15:0] io_rx_a,
 inout wire [15:0] io_rx_b
 );	
 
 
  // assorted stuff pasted from original code
  // ***********************************************************************
 
  assign MYSTERY_SIGNAL = 1'b0;
   
   wire clk64,clk128;
   
   wire WR = usbctl[0];
   wire RD = usbctl[1];
   wire OE = usbctl[2];

   wire have_space, have_pkt_rdy;
   assign usbrdy[0] = have_space;
   assign usbrdy[1] = have_pkt_rdy;

   wire   tx_underrun, rx_overrun;    
   wire   clear_status = FX2_1;
   assign FX2_2 = rx_overrun;
   assign FX2_3 = tx_underrun;
      
   wire [15:0] usbdata_out;
   
   wire [7:0]  settings;
   
   // Tri-state bus macro
   bustri bustri( .data(usbdata_out),.enabledt(OE),.tridata(usbdata) );

   assign      clk64 = master_clk;
   
   wire        strobe_interp, tx_sample_strobe;
   wire        tx_empty;
   
   wire        serial_strobe;
   wire [6:0]  serial_addr;
   wire [31:0] serial_data;

   reg [15:0] debug_counter;
   reg [15:0] loopback_i_0,loopback_q_0;
 
 
   // Control functions section of original code
   // These allow for things like setting of registers on the FPGA
   // with the usrper command.
   // ***********************************************************************
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   // Control Functions

   wire [31:0] capabilities;
   assign      capabilities[7] =   `TX_CAP_HB;
   assign      capabilities[6:4] = `TX_CAP_NCHAN;
   assign      capabilities[3] =   `RX_CAP_HB;
   assign      capabilities[2:0] = `RX_CAP_NCHAN;


   serial_io serial_io
     ( .master_clk(clk64),.serial_clock(SCLK),.serial_data_in(SDI),
       .enable(SEN_FPGA),.reset(1'b0),.serial_data_out(SDO),
       .serial_addr(serial_addr),.serial_data(serial_data),.serial_strobe(serial_strobe),
       .readback_0({io_rx_a,io_tx_a}),.readback_1({io_rx_b,io_tx_b}),.readback_2(capabilities),.readback_3(32'hf0f0931a),
       .readback_4(rssi_0),.readback_5(rssi_1),.readback_6(rssi_2),.readback_7(rssi_3)
       );

   wire [15:0] reg_0,reg_1,reg_2,reg_3;
   master_control master_control
     ( .master_clk(clk64),.usbclk(usbclk),
       .serial_addr(serial_addr),.serial_data(serial_data),.serial_strobe(serial_strobe),
       .tx_bus_reset(tx_bus_reset),.rx_bus_reset(rx_bus_reset),
       .tx_dsp_reset(tx_dsp_reset),.rx_dsp_reset(rx_dsp_reset),
       .enable_tx(enable_tx),.enable_rx(enable_rx),
       .interp_rate(interp_rate),.decim_rate(decim_rate),
       .tx_sample_strobe(tx_sample_strobe),.strobe_interp(strobe_interp),
       .rx_sample_strobe(rx_sample_strobe),.strobe_decim(strobe_decim),
       .tx_empty(tx_empty),
       //.debug_0(rx_a_a),.debug_1(ddc0_in_i),
       .debug_0(tx_debugbus[15:0]),.debug_1(tx_debugbus[31:16]),
       .debug_2(rx_debugbus[15:0]),.debug_3(rx_debugbus[31:16]),
       .reg_0(reg_0),.reg_1(reg_1),.reg_2(reg_2),.reg_3(reg_3) );
   

// The following block has been commented out to give
// the FPGA complete control over the general purpose
// digital io pints (eg io_tx_a, io_rx_a, etc).


//   io_pins io_pins
//     (.io_0(io_tx_a),.io_1(io_rx_a),.io_2(io_tx_b),.io_3(io_rx_b),
 //     .reg_0(reg_0),.reg_1(reg_1),.reg_2(reg_2),.reg_3(reg_3),
 //     .clock(clk64),.rx_reset(rx_dsp_reset),.tx_reset(tx_dsp_reset),
 //     .serial_addr(serial_addr),.serial_data(serial_data),.serial_strobe(serial_strobe));
   
   
   
 
 
  // Aviv's code for the fpga...
  // ***********************************************************************



// ANALOG OUTPUTS
// tx_a_a, tx_a_b, tx_b_a, tx_b_b
// ANALOG INPUTS
// rx_a_a, rx_a_b, rx_b_a, rx_b_b
//
// Note! The outputs and inputs do not currently have the same naming convention
// due to a screw up on my part that I have not yet corrected. Read on.



   // dac output wires
   wire [13:0] tx_a_a, tx_a_b, tx_b_a, tx_b_b;
   // tx_a_b means output B on daughterboard A.
   // tx_b_a means output A on daughterboard B
   // note that this is inconsistent with the rx_ convention! 
   // this is my doing, and I'm sorry.
   // i changed the tx convention to this, because I think it makes infinitely more sense
   
   // the rx convention is:
   // rx_a_b means input A on board B
   // rx_b_a means input B on board A
   // this is the original convention.
      
   // transmit interleave   
   reg txsync;
   assign TXSYNC_A = txsync;
   assign TXSYNC_B = txsync;
   always @(posedge clk64)
	txsync <= ~txsync;		
   assign tx_a[13:0] = txsync ? tx_a_b[13:0] : tx_a_a[13:0];
   assign tx_b[13:0] = txsync ? tx_b_b[13:0] : tx_b_a[13:0];
	

// REGISTERS
// **************************************************************
// the following section creates all the run-time settable registers
// for the various run-time parameters, like
// feedback gains, mixer s, etc.
// These values are set during run time with the usrper command.

// the setting_reg calls are calls to the original USRP module which create the 
// logic for these registers to be set by the usrper command.

	
	// register addresses:
	// 65 : PA
	// 66 : IA
	// 67 : DA
	// 68 : PB
	// 69 : IB
	// 70 : DB
	// 71 : PC
	// 72 : IC
	// 73 : DC
	// 74 : PD
	// 75 : ID
	// 76 : DD
	// 77 : MixerPhase1
	// 78 : MixerPhase2
	// 79 : MixerPhase3
	// 80 : MixerPhase4
	// 81 : MixerGain1
	// 82 : MixerGain2
	// 83 : MixerGain3
	// 84 : MixerGain4
	// 85 : Triangle Generator Max
	// 86 : Triangle Generator Min
	// 87 : Triangle Generator Step Size
	// 88 : Output 1 Selector
	// 89 : Output 2 Selector
	// 90 : Output 3 Selector
	// 91 : Output 4 Selector
	// 92 : Linear combination 1 Gain 1
	// 93 : Linear combination 1 Gain 2
	// 94 : Linear combination 2 Gain 1
	// 95 : Linear combination 2 Gain 2
	// 96 : Linear combination 3 Gain 1
	// 97 : Linear combination 3 Gain 2
	// 100: Threshold 1
	// 101: Threshold 2
	// 102: Threshold 3
	// 103: Threshold 4
	// 104: Program State
	// 105: PID Input MUX 1
	// 106: PID Input MUX 2
	// 107: PID Input MUX 3
	// 108: unused
	// 109: Linear combination 1 input 1 mux  (0=mixer 1, 1=mixer 2, 2=mixer 3 etc)
	// 110: Linear combination 1 input 2 mux
	// 111: Linear combination 2 input 1 mux
	// 112: Linear combination 2 input 2 mux
	// 113: Enable oscillator output (0 = enabled, 1 = disabled)
	// 114: Linear combination 1 input 2 gated on rx_a_a above threshold? (1 = yes, 0 = no)
	// 115: Linear combination 2 input 2 gated on rx_b_a above threshold? (1 = yes, 0 = no)	
	// 116: General purpose 32 bit value, genreg1
	// 117: General purpose 32 bit value, genreg2
	// 118: General purpose 32 bit value, genreg3
	// 119: General purpose 32 bit value, genreg4
	// 120: PID 1 Autoactivate condition
	// 121: PID 2 Autoactivate condition
	// 122: NA
	// 123: NA
	
    // PID control gain coefficients for controllers a, b, c, and d
    // (also known as controllers 1, 2, 3, and 4)
	wire [31:0] PA, PB, PC, PD, IA, IB, IC, ID, DA, DB, DC, DD;
		
	
	// Make the PID gain coefficient registers into computer-settable registers.
	// These are set through the usrper program's write_fpga_reg command
	setting_reg #(65) sr_PA(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(PA));
	setting_reg #(66) sr_IA(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(IA));
	setting_reg #(67) sr_DA(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(DA));
	setting_reg #(68) sr_PB(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(PB));
	setting_reg #(69) sr_IB(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(IB));
	setting_reg #(70) sr_DB(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(DB));
	setting_reg #(71) sr_PC(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(PC));
	setting_reg #(72) sr_IC(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(IC));
	setting_reg #(73) sr_DC(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(DC));
	setting_reg #(74) sr_PD(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(PD));
	setting_reg #(75) sr_ID(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(ID));
	setting_reg #(76) sr_DD(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(DD));


	wire signed [5:0] MixerPhase1, MixerPhase2, MixerPhase3, MixerPhase4;

	// Phase / invert registers for 4 mixer/demodulators
	setting_reg #(77) sr_MP1(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(MixerPhase1));
	setting_reg #(78) sr_MP2(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(MixerPhase2));
	setting_reg #(79) sr_MP3(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(MixerPhase3));
	setting_reg #(80) sr_MP4(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(MixerPhase4));



	// post-mixer gain regsiters (first 8 bits only are used, i range is 0 to 255)
	
	wire signed [15:0] MixerGain1, MixerGain2, MixerGain3, MixerGain4;

	setting_reg #(81) sr_MG1(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(MixerGain1));
	setting_reg #(82) sr_MG2(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(MixerGain2));
	setting_reg #(83) sr_MG3(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(MixerGain3));
	setting_reg #(84) sr_MG4(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(MixerGain4));
	

	// triangle generator registers
	wire signed [31:0] triangleMax, triangleMin, triangleStep;
	setting_reg #(85) sr_trmax(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(triangleMax));
	setting_reg #(86) sr_trmin(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(triangleMin));
	setting_reg #(87) sr_trstep(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(triangleStep));



// mux registers

	wire [31:0] mux1, mux2, mux3, mux4;
	reg [31:0]  new_mux1, new_mux2, new_mux3, new_mux4;
	reg			change_mux1, change_mux2, change_mux3, change_mux4;
	setting_reg #(88) sr_mux1(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(mux1),
								.overrideStrobe(change_mux1), .overrideIn(new_mux1));
	setting_reg #(89) sr_mux2(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(mux2),
								.overrideStrobe(change_mux2), .overrideIn(new_mux2));
	setting_reg #(90) sr_mux3(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(mux3),
								.overrideStrobe(change_mux3), .overrideIn(new_mux3));
	setting_reg #(91) sr_mux4(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(mux4),
								.overrideStrobe(change_mux4), .overrideIn(new_mux4));



// linear combination registers

	wire signed [31:0] lc1_1, lc1_2, lc2_1, lc2_2, lc3_1, lc3_2;
	setting_reg #(92) sr_lc11(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(lc1_1));
	setting_reg #(93) sr_lc12(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(lc1_2));
	setting_reg #(94) sr_lc21(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(lc2_1));
	setting_reg #(95) sr_lc22(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(lc2_2));
	setting_reg #(96) sr_lc31(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(lc3_1));
	setting_reg #(97) sr_lc32(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(lc4_2));


// threshold  registers

	wire signed [31:0] thr1, thr2, thr3, thr4;
	setting_reg #(100) sr_thr1(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(thr1));
	setting_reg #(101) sr_thr2(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(thr2));
	setting_reg #(102) sr_thr3(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(thr3));
	setting_reg #(103) sr_thr4(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(thr4));


// State machine register.
	wire [31:0] user_program_state;
	wire changed_user_program_state;
//	wire reset_user_program_state = (changed_user_program_state && (user_program_state!=0));
	setting_reg #(104) sr_progstate(
		.clock(master_clk),
		.strobe(serial_strobe),
		.addr(serial_addr),
		.in(serial_data),
		.out(user_program_state),
		.changed(changed_user_program_state),
//		.reset(reset_user_program_state)
		);


// PID Input muxes		
	wire signed [31:0] pidin_mux1, pidin_mux2, pidin_mux3;
	setting_reg #(105) sr_pinm1(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(pidin_mux1));
	setting_reg #(106) sr_pinm2(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(pidin_mux2));
	setting_reg #(107) sr_pinm3(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(pidin_mux3));	


// Linear combination input muxes
	wire signed [31:0] lin1_inmux1, lin1_inmux2, lin2_inmux1, lin2_inmux2;
	setting_reg #(109) sr_linmux11(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(lin1_inmux1));
	setting_reg #(110) sr_linmux12(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(lin1_inmux2));
	setting_reg #(111) sr_linmux21(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(lin2_inmux1));
	setting_reg #(112) sr_linmux22(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(lin2_inmux2));
	
	
	wire enableOscOutput;
	setting_reg #(113) enableOscOutputReg(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(enableOscOutput));

	wire lincomb1gate, lincomb2gate;
	setting_reg #(114) lincomb1gateReg(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(lincomb1gate));
	setting_reg #(115) lincomb2gateReg(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(lincomb2gate));
	
	wire signed [31:0] genreg1, genreg2, genreg3, genreg4;
	setting_reg #(116) genreg1Reg(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(genreg1));
	setting_reg #(117) genreg2Reg(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(genreg2));
	setting_reg #(118) genreg3Reg(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(genreg3));
	setting_reg #(119) genreg4Reg(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(genreg4));
	
	wire signed [31:0] PID1autoact_mux, PID2autoact_mux, PID3autoact_mux, PID4autoact_mux;
	setting_reg #(120) pidautoact1Reg(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(PID1autoact_mux));
	setting_reg #(121) pidautoact2Reg(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(PID2autoact_mux));
	setting_reg #(122) pidautoact3Reg(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(PID3autoact_mux));
	setting_reg #(123) pidautoact4Reg(.clock(master_clk),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(PID4autoact_mux));


// INSTANTIATION OF MODULES
// ***************************************************************************************
// This section of the code actually creates all the various mixers, filters, feedback controllers,
// etc



// Create triangle wave generator
// Note also that the sync output of the triangle generator
// is being sent to digital io pin io_tx_a[1]
// to facilitate syncing a scope to the triangle wave.
	
   wire signed [13:0] triangleWaveOutput;
   
	TriangleWaveGenerator triangleGenerator(
		.clock(master_clk),
		.stepSize(triangleStep), 
		.maxOut(triangleMax), 
		.minOut(triangleMin),
		//input wire reset,
		.out(triangleWaveOutput),
		.sync(io_tx_a[1])
		);
 

// Create 1MHz oscillator
// and connect its output to digital io pin io_tx_b[0]
// by using a 2MHz mini circuits low-pass filter, the output from this 
// pin was a beautiful 1MHz sine wave. Using a digital pin instead of a complete
// analog output for outputting this oscillator is a much more
// efficient use of resources, and also saves me the trouble of figuring out how to 
// implement a sine lookup table. (though that shouldn't be hard either)
	wire signed [5:0] OscCounter;
	wire OscSign;
	assign io_tx_a[0] = enableOscOutput? 0 : OscSign;
	OneMHzOscillator myOscillator(.clk64(master_clk), .out(OscSign), .counter(OscCounter));
	
	

// Create 3 mixers

	wire signed [13:0] mixer1Output;
	FilteredMixerModule mixer1(.master_clk(clk64),
		.tx_out(mixer1Output), 
		.rx_in(rx_a_a), 
		.gainRegIn(MixerGain1[15:0]), 
		.phaseRegIn(MixerPhase1),
		.OscCounter(OscCounter),
		.OscSign(OscSign));

	// mixer 2 has a more agressive low pass output filter
	// (not right now)
	/*defparam mixer2.nPostFilterAverageSamples = 4096;
	defparam mixer2.log2nPostFilterAverageSamples = 12;*/
	wire signed [13:0] mixer2Output;
	FilteredMixerModule mixer2(.master_clk(clk64),
		.tx_out(mixer2Output), 
		.rx_in(rx_b_a),									// input B of dboard A 
		.gainRegIn(MixerGain2[15:0]), 
		.phaseRegIn(MixerPhase2),
		.OscCounter(OscCounter),
		.OscSign(OscSign));
   
	wire signed [13:0] mixer3Output;
	FilteredMixerModule mixer3(.master_clk(clk64),
		.tx_out(mixer3Output), 
		.rx_in(rx_a_b),									// input A of dboard B 
		.gainRegIn(MixerGain3[15:0]), 
		.phaseRegIn(MixerPhase3),
		.OscCounter(OscCounter),
		.OscSign(OscSign));



// create 3 PID controllers

	reg signed [11:0] PID1Input;
	wire signed [13:0] PID1Output, PID1ForceInput;	
	reg i1hold, i1reset, i1force;
	PIDfeedback pida(
		.clock(master_clk), 
		.measSignalIn(PID1Input), 
		.controlSignalOut(PID1Output),
		.pGainIn(PA),.iGainIn(IA),.dGainIn(DA),
		.intHold(i1hold), .intReset(i1reset), 
		.intSetValueFromOverride(i1force), .overrideControlSignalIn(PID1ForceInput));

   

   
   	reg signed [11:0] PID2Input;
   	wire signed [13:0] PID2Output, PID2ForceInput;
   	reg i2hold, i2reset, i2force;
	PIDfeedback pidb(
		.clock(master_clk), 
		.measSignalIn(PID2Input), 
		.controlSignalOut(PID2Output),
		.pGainIn(PB),.iGainIn(IB),.dGainIn(DB),
		.intHold(i2hold), .intReset(i2reset), 
		.intSetValueFromOverride(i2force), .overrideControlSignalIn(PID2ForceInput));
   


// PID CONTROLLER #3 currently disabled for faster compilation time

   	reg signed [11:0] PID3Input;
   	wire signed [13:0] PID3Output, PID3ForceInput;
   	reg i3hold, i3reset, i3force;
/*	PIDfeedback pidc(
		.clock(master_clk), 
		.measSignalIn(PID3Input), 
		.controlSignalOut(PID3Output),
		.pGainIn(PC),.iGainIn(IC),.dGainIn(DC),
		.intHold(i3hold), .intReset(i3reset), 
		.intSetValueFromOverride(i3force), .overrideControlSignalIn(PID3ForceInput));
  */
   
   // all three "force" values come from triangle generator
   assign PID1ForceInput = triangleWaveOutput;
   assign PID2ForceInput = triangleWaveOutput;   
   assign PID3ForceInput = triangleWaveOutput;


// Create linear combination modules


	reg signed [13:0] lincomb1input1, lincomb1input2, lincomb2input1, lincomb2input2;

	wire signed [13:0] LinearCombinationOutput1;
	LinearCombination lc1(
		.clk64(master_clk),
		.input1(lincomb1input1),
		.input2(lincomb1input2),
		.gain1(lc1_1),
		.gain2(lc1_2),
		.outputWire(LinearCombinationOutput1));   

	wire signed [13:0] LinearCombinationOutput2;
	LinearCombination lc2(
		.clk64(master_clk),
		.input1(lincomb2input1),
		.input2(lincomb2input2),
		.gain1(lc2_1),
		.gain2(lc2_2),
		.outputWire(LinearCombinationOutput2));   
   
   
// EXECUTIVE LOGIC
// *********************************************************************************************************   
// This part of the code handles
// output selection (ie has output MUXes that chose which value to send to the output based on the output selector registers)
// and other "executive logic" functions, such as shutting off the 
// PID integrators when they are not connected to the analog outputs.

reg signed [13:0] out_a_a, out_a_b, out_b_a, out_b_b;
assign tx_a_a = out_a_a;
assign tx_a_b = out_a_b;
assign tx_b_a = out_b_a;
assign tx_b_b = out_b_b;

// state machine states
parameter s_idle 			= 0,
          s_lockscan1		= 1,
          s_lockscan1_1		= 2,
          s_lockscan1_2		= 3,
          s_lockscan2		= 4,
          s_lockscan2_1		= 5,
          s_lockscan2_2		= 6,
          s_idle_waiting	= 7;
          
          
reg [32:0] program_state;          

reg PID1autoact, PID2autoact;
reg oldPID1autoact, oldPID2autoact;


   
always @(posedge master_clk) begin

	// PID input muxes
	//
	// 0: Pid N gets mixer N (default behavior)
	// 1: mixer 1
	// 2: mixer 2
	// 3: mixer 3
	// 4: mixer 4 (not enabled)
	// 5-8: Linear combinations 4-8.
	// 9-12: Inputs 1-4
	
	case (pidin_mux1)
		0:
			PID1Input<=(mixer1Output>>>2);
		1:
			PID1Input<=(mixer1Output>>>2);
		2:
			PID1Input<=(mixer2Output>>>2);
		3:
			PID1Input<=(mixer3Output>>>2);
		5:
			PID1Input<=(LinearCombinationOutput1>>>2);
		6:
			PID1Input<=(LinearCombinationOutput2>>>2);
		//7:
		//8:
		9:
			PID1Input<=rx_a_a;
		10:
			PID1Input<=rx_b_a;
		11:
			PID1Input<=rx_a_b;
		12:
			PID1Input<=rx_b_b;
			
		13:
			PID1Input<=(triangleWaveOutput>>>2);
	endcase

	case (pidin_mux2)
		0:
			PID2Input<=(mixer2Output>>>2);
		1:
			PID2Input<=(mixer1Output>>>2);
		2:
			PID2Input<=(mixer2Output>>>2);
		3:
			PID2Input<=(mixer3Output>>>2);
		5:
			PID2Input<=(LinearCombinationOutput1>>>2);
		6:
			PID2Input<=(LinearCombinationOutput2>>>2);	
		9:
			PID2Input<=rx_a_a;
		10:
			PID2Input<=rx_b_a;
		11:
			PID2Input<=rx_a_b;
		12:
			PID2Input<=rx_b_b;
		13:
			PID2Input<=(triangleWaveOutput>>>2);
	endcase
	
	case (pidin_mux3)
		0:
			PID3Input<=(mixer3Output>>>2);
		1:
			PID3Input<=(mixer1Output>>>2);
		2:
			PID3Input<=(mixer2Output>>>2);
		3:
			PID3Input<=(mixer3Output>>>2);
		5:
			PID3Input<=(LinearCombinationOutput1>>>2);
		6:
			PID3Input<=(LinearCombinationOutput2>>>2);		
		9:
			PID3Input<=rx_a_a;
		10:
			PID3Input<=rx_b_a;
		11:
			PID3Input<=rx_a_b;
		12:
			PID3Input<=rx_b_b;	
		13:
			PID3Input<=(triangleWaveOutput>>>2);			
	endcase


	// Linear combination input muxes
	
	case (lin1_inmux1)
		0:
			lincomb1input1<=mixer1Output;
		1:
			lincomb1input1<=mixer2Output;
		2:
			lincomb1input1<=mixer3Output;
		
		4:
			lincomb1input1<=(rx_a_a<<<2);
		5:
			lincomb1input1<=(rx_b_a<<<2);
		6:
			lincomb1input1<=(rx_a_b<<<2);
		7:
			lincomb1input1<=(rx_b_b<<<2);
			
		8:
			lincomb1input1<=genreg1;
		9:
			lincomb1input1<=genreg2;
		10:
			lincomb1input1<=genreg3;			
		11:
			lincomb1input1<=genreg4;
		
		12:
			lincomb1input1<=triangleWaveOutput;
	endcase
	
	// L combination input 2 can be gated, by setting lincomb1gate 
	if ( (~lincomb1gate) || (rx_a_a<thr1) ) begin
		case (lin1_inmux2)
			0:
				lincomb1input2<=mixer1Output;
			1:
				lincomb1input2<=mixer2Output;
			2:
				lincomb1input2<=mixer3Output;
			4:
				lincomb1input2<=(rx_a_a<<<2);
			5:
				lincomb1input2<=(rx_b_a<<<2);
			6:
				lincomb1input2<=(rx_a_b<<<2);
			7:
				lincomb1input2<=(rx_b_b<<<2);
			8:
				lincomb1input2<=genreg1;
			9:
				lincomb1input2<=genreg2;
			10:
				lincomb1input2<=genreg3;			
			11:
				lincomb1input2<=genreg4;
				
			12:
				lincomb1input2<=triangleWaveOutput;
		endcase
	end else lincomb1input2<=0;
	
	case (lin2_inmux1)
		0:
			lincomb2input1<=mixer1Output;
		1:
			lincomb2input1<=mixer2Output;
		2:
			lincomb2input1<=mixer3Output;
			
		4:
			lincomb2input1<=(rx_a_a<<<2);
		5:
			lincomb2input1<=(rx_b_a<<<2);
		6:
			lincomb2input1<=(rx_a_b<<<2);
		7:
			lincomb2input1<=(rx_b_b<<<2);			
		8:
			lincomb2input1<=genreg1;
		9:
			lincomb2input1<=genreg2;
		10:
			lincomb2input1<=genreg3;			
		11:
			lincomb2input1<=genreg4;

		12:
			lincomb2input1<=triangleWaveOutput;
		endcase

	// L combination #2 input 2 can also be gated
	if ( (~lincomb2gate) || (rx_b_a<thr2) ) begin	
		case (lin2_inmux2)
			0:
				lincomb2input2<=mixer1Output;
			1:
				lincomb2input2<=mixer2Output;
			2:
				lincomb2input2<=mixer3Output;
				
			4:
				lincomb2input2<=(rx_a_a<<<2);
			5:
				lincomb2input2<=(rx_b_a<<<2);
			6:
				lincomb2input2<=(rx_a_b<<<2);
			7:
				lincomb2input2<=(rx_b_b<<<2);				
			8:
				lincomb2input2<=genreg1;
			9:
				lincomb2input2<=genreg2;
			10:
				lincomb2input2<=genreg3;			
			11:
				lincomb2input2<=genreg4;
				
			12:
				lincomb2input2<=triangleWaveOutput;
		endcase
	end else lincomb2input2<=0;


	// output MUX logic
	// 0: PID N output
	// 1: triangle wave output
	// 2: loopback input N
	// 3: output 0.
	
	case (mux1)
		0: begin
			out_a_a<=PID1Output;
			i1hold<=0;
			i1reset<=0;
			i1force<=0;
			end
		1: begin
			out_a_a<=triangleWaveOutput;
			i1hold<=1;
			i1reset<=1;
			i1force<=1;
			end
		2: begin
			out_a_a<=(rx_a_a<<<2);
			i1hold<=1;
			i1reset<=1;
			end
		3: begin
			out_a_a<=0;
			i1hold<=1;
			i1reset<=1;
			end
	endcase

	case (mux2)
		0: begin
			out_a_b<=PID2Output;
			i2hold<=0;
			i2reset<=0;
			i2force<=0;			
			end
		1: begin
			out_a_b<=triangleWaveOutput;
			i2hold<=1;
			i2reset<=1;
			i2force<=1;		
			end
		2: begin
			out_a_b<=(rx_b_a<<<2);
			i2hold<=1;
			i2reset<=1;
			end
		3: begin
			out_a_b<=0;
			i2hold<=1;
			i2reset<=1;
			end			
	endcase	
	
	case (mux3)
		0: begin
			out_b_a<=PID3Output;
			i3hold<=0;
			i3reset<=0;
			i3force<=0;			
			end
		1: begin
			out_b_a<=triangleWaveOutput;
			i3hold<=1;
			i3reset<=1;
			i3force<=1;			
			end
		2: begin
			out_b_a<=(rx_a_b<<<2);
			i3hold<=1;
			i3reset<=1;
			end
		3: begin
			out_b_a<=0;
			i3hold<=1;
			i3reset<=1;
			end			
			
	endcase	
	
	// channel 4 output mux
	// this output is for general purpose monitoring of various internal signals, and is 
	// very useful for setting gains and monitoring demodulation, etc.
	//
	// note, some of the listed mux values correspond to modules that are not enabled,
	// and hence do not actually function
	//
	// 0-3:   mixer outputs 1-4.
	// 4-7:   linear combination outputs 1-4
	// 8-11:  threshold trigger outputs 1-4
	// 12-15: input loopbacks 1-4
	// 16-19: threshold monitor outputs 1-4
	// 20:    triangle wave output
	// 21:    zero
	// 22:    8191 (max out)
	// 23:    -8192 (min out)
	// 24-27: PID Output 1-4
	//
	// (debug purposes)
	// 1000:  program_state<<<7 (debug purposes)
	// 1001:  user_program_state<<<7
	// 1002:  mux1<<<7
	// 1003:  mux2<<<7
	// 1004:  mux3<<<7
	
	case (mux4)
		0: 
			out_b_b<=mixer1Output;
		1: 
			out_b_b<=mixer2Output;
		2:
			out_b_b<=mixer3Output;
//		3 not used		
		4:
			out_b_b<=LinearCombinationOutput1;
		5:
			out_b_b<=LinearCombinationOutput2;
// 		6 not use
//		7 not used
		8:
			out_b_b<=(rx_a_a<thr1) ? 500 : -500;
		9:
			out_b_b<=(rx_b_a<thr2) ? 500 : -500;
		10: 
			out_b_b<=(rx_a_b<thr3) ? 500 : -500;
		11: 
			out_b_b<=(rx_b_b<thr4) ? 500 : -500;
		12:
			out_b_b<=(rx_a_a<<<2);
		13:
			out_b_b<=(rx_b_a<<<2);
		14:
			out_b_b<=(rx_a_b<<<2);
		15: 
			out_b_b<=(rx_b_b<<<2);
		16: 
			out_b_b<=(thr1<<<2);
		17:
			out_b_b<=(thr2<<<2);
		18: 
			out_b_b<=(thr3<<<2);
		//19: not used
		20:
			out_b_b<=triangleWaveOutput;
		21:
			out_b_b<=0;
		22: 
			out_b_b<=8191;
		23:
			out_b_b<=-8192;
		24:
			out_b_b<=PID1Output;
		25:
			out_b_b<=PID2Output;
		26:
			out_b_b<=PID3Output;
			
		28:
			out_b_b<=genreg1;
		29:
			out_b_b<=genreg2;
		30:
			out_b_b<=genreg3;
		31:
			out_b_b<=genreg4;			

		
		// debug outputs
		1000:
			out_b_b<=(program_state<<<7);
		1001:
			out_b_b<=(user_program_state<<<7);
		1002:
			out_b_b<=(mux1<<<7);
		1003:
			out_b_b<=(mux2<<<7);
		1004:
			out_b_b<=(mux3<<<7);
	endcase	
	

	// PID Autoactivation muxes
	//0:	"Never",
	//1:  "Always",
	//2:  "Input 1 > threshold?",
	//3:  "Input 2 > threshold?",
	//4:  "Input 3 > threshold?",
	//5:  "Input 4 > threshold?",
	//6:  "Input 1 < threshold?",
	//7:  "Input 2 < threshold?",
	//8:  "Input 3 < threshold?",
	//9:  "Input 4 < threshold?"
	
	case (PID1autoact_mux)
		0:
			PID1autoact<=0;
		1:
			PID1autoact<=1;
		2:
			PID1autoact<=rx_a_a<thr1;
		3:
			PID1autoact<=rx_b_a<thr2;
		4: 
			PID1autoact<=rx_a_b<thr3;
		5: 
			PID1autoact<=rx_b_b<thr4;
		6:
			PID1autoact<=rx_a_a>thr1;
		7:
			PID1autoact<=rx_b_a>thr2;
		8: 
			PID1autoact<=rx_a_b>thr3;
		9: 
			PID1autoact<=rx_b_b>thr4;
	endcase
	
	oldPID1autoact<=PID1autoact;	
	
	case (PID2autoact_mux)
		0:
			PID2autoact<=0;
		1:
			PID2autoact<=1;
		2:
			PID2autoact<=rx_a_a<thr1;
		3:
			PID2autoact<=rx_b_a<thr2;
		4: 
			PID2autoact<=rx_a_b<thr3;
		5: 
			PID2autoact<=rx_b_b<thr4;
		6:
			PID2autoact<=rx_a_a>thr1;
		7:
			PID2autoact<=rx_b_a>thr2;
		8: 
			PID2autoact<=rx_a_b>thr3;
		9: 
			PID2autoact<=rx_b_b>thr4;
	endcase
	
	oldPID2autoact<=PID2autoact;
	
	
	
	// PID Auto-activation
	
	if (PID1autoact && ~oldPID1autoact) begin
		change_mux1<=1;
		new_mux1<=1;
	end
	else begin
		change_mux1<=0;
	end
	
	
	if (PID2autoact && ~oldPID2autoact) begin
		change_mux2<=1;
		new_mux2<=1;
	end
	else begin
		change_mux2<=0;
	end
	
// Executive function, state machine stuff, etc.

// "user entry points" to state machine.
// deprecated, for now
/*
	if (user_program_state==0) begin
		program_state<=s_idle_waiting;
	end
	else if (changed_user_program_state) begin
		case (user_program_state)
			1:
				program_state<=s_idle;
			2:
				program_state<=s_lockscan1;
			3: 
				program_state<=s_lockscan2;
		endcase
	end
*/

// state machine logic	
// deprecated, for now
/*
	case (program_state)
		s_idle:
		begin
			change_mux1<=0;
			change_mux2<=0;
			change_mux3<=0;
			change_mux4<=0;
		end
		
		s_idle_waiting:
		begin
			change_mux1<=0;
			change_mux2<=0;
			change_mux3<=0;
			change_mux4<=0;
		end

		// lockscan1 program
		// ************
		s_lockscan1:
		begin // put channel 1 in triangle wave output mode
			new_mux1<=1;
			change_mux1<=1;
			program_state<=s_lockscan1_1;
		end
		
		s_lockscan1_1:
		begin // 1 cycle setup time
			change_mux1<=0;	
			program_state<=s_lockscan1_2;
		end
		
		s_lockscan1_2:
		begin
			if (rx_a_a<thr1) begin
				new_mux1<=0;
				change_mux1<=1;
				program_state<=s_idle;
			end
		end
		
		
		// lockscan2 program
		// ************
		s_lockscan2:
		begin // put channel 1 in triangle wave output mode
			new_mux2<=1;
			change_mux2<=1;
			program_state<=s_lockscan2_1;
		end
		
		s_lockscan2_1:
		begin // 1 cycle setup time
			change_mux2<=0;	
			program_state<=s_lockscan2_2;
		end
		
		s_lockscan2_2: 
		begin
			if (rx_b_a<thr2) begin
				new_mux2<=0;
				change_mux2<=1;
				program_state<=s_idle;
			end
		end
				
	endcase	
*/	

end      




   
   
   
   
   // miscellaneus wires and registers from original code
wire [31:0] tx_debugbus, rx_debugbus;
   
   
 
 
 
 // the original usrp code is commented out and follows:
 
/*
   wire [15:0] debugdata,debugctrl;
   assign MYSTERY_SIGNAL = 1'b0;
   
   wire clk64,clk128;
   
   wire WR = usbctl[0];
   wire RD = usbctl[1];
   wire OE = usbctl[2];

   wire have_space, have_pkt_rdy;
   assign usbrdy[0] = have_space;
   assign usbrdy[1] = have_pkt_rdy;

   wire   tx_underrun, rx_overrun;    
   wire   clear_status = FX2_1;
   assign FX2_2 = rx_overrun;
   assign FX2_3 = tx_underrun;
      
   wire [15:0] usbdata_out;
   
   wire [3:0]  dac0mux,dac1mux,dac2mux,dac3mux;
   
   wire        tx_realsignals;
   wire [3:0]  rx_numchan;
   wire [2:0]  tx_numchan;
   
   wire [7:0]  interp_rate, decim_rate;
   wire [31:0] tx_debugbus, rx_debugbus;
   
   wire        enable_tx, enable_rx;
   wire        tx_dsp_reset, rx_dsp_reset, tx_bus_reset, rx_bus_reset;
   wire [7:0]  settings;
   
   // Tri-state bus macro
   bustri bustri( .data(usbdata_out),.enabledt(OE),.tridata(usbdata) );

   assign      clk64 = master_clk;

   wire [15:0] ch0tx,ch1tx,ch2tx,ch3tx; //,ch4tx,ch5tx,ch6tx,ch7tx;
   wire [15:0] ch0rx,ch1rx,ch2rx,ch3rx,ch4rx,ch5rx,ch6rx,ch7rx;
   
   // TX
   wire [15:0] i_out_0,i_out_1,q_out_0,q_out_1;
   wire [15:0] bb_tx_i0,bb_tx_q0,bb_tx_i1,bb_tx_q1;  // bb_tx_i2,bb_tx_q2,bb_tx_i3,bb_tx_q3;
   
   wire        strobe_interp, tx_sample_strobe;
   wire        tx_empty;
   
   wire        serial_strobe;
   wire [6:0]  serial_addr;
   wire [31:0] serial_data;

   reg [15:0] debug_counter;
   reg [15:0] loopback_i_0,loopback_q_0;
   
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   // Transmit Side
`ifdef TX_ON
   assign      bb_tx_i0 = ch0tx;
   assign      bb_tx_q0 = ch1tx;
   assign      bb_tx_i1 = ch2tx;
   assign      bb_tx_q1 = ch3tx;
   
   tx_buffer tx_buffer
     ( .usbclk(usbclk), .bus_reset(tx_bus_reset),
       .usbdata(usbdata),.WR(WR), .have_space(have_space),
       .tx_underrun(tx_underrun), .clear_status(clear_status),
       .txclk(clk64), .reset(tx_dsp_reset),
       .channels({tx_numchan,1'b0}),
       .tx_i_0(ch0tx),.tx_q_0(ch1tx),
       .tx_i_1(ch2tx),.tx_q_1(ch3tx),
       .txstrobe(strobe_interp),
       .tx_empty(tx_empty),
       .debugbus(tx_debugbus) );
   
 `ifdef TX_EN_0
   tx_chain tx_chain_0
     ( .clock(clk64),.reset(tx_dsp_reset),.enable(enable_tx),
       .interp_rate(interp_rate),.sample_strobe(tx_sample_strobe),
       .interpolator_strobe(strobe_interp),.freq(),
       .i_in(bb_tx_i0),.q_in(bb_tx_q0),.i_out(i_out_0),.q_out(q_out_0) );
 `else
   assign      i_out_0=16'd0;
   assign      q_out_0=16'd0;
 `endif

 `ifdef TX_EN_1
   tx_chain tx_chain_1
     ( .clock(clk64),.reset(tx_dsp_reset),.enable(enable_tx),
       .interp_rate(interp_rate),.sample_strobe(tx_sample_strobe),
       .interpolator_strobe(strobe_interp),.freq(),
       .i_in(bb_tx_i1),.q_in(bb_tx_q1),.i_out(i_out_1),.q_out(q_out_1) );
 `else
   assign      i_out_1=16'd0;
   assign      q_out_1=16'd0;
 `endif

   setting_reg #(`FR_TX_MUX) 
     sr_txmux(.clock(clk64),.reset(tx_dsp_reset),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),
	      .out({dac3mux,dac2mux,dac1mux,dac0mux,tx_realsignals,tx_numchan}));
   
   wire [15:0] tx_a_a = dac0mux[3] ? (dac0mux[1] ? (dac0mux[0] ? q_out_1 : i_out_1) : (dac0mux[0] ? q_out_0 : i_out_0)) : 16'b0;
   wire [15:0] tx_b_a = dac1mux[3] ? (dac1mux[1] ? (dac1mux[0] ? q_out_1 : i_out_1) : (dac1mux[0] ? q_out_0 : i_out_0)) : 16'b0;
   wire [15:0] tx_a_b = dac2mux[3] ? (dac2mux[1] ? (dac2mux[0] ? q_out_1 : i_out_1) : (dac2mux[0] ? q_out_0 : i_out_0)) : 16'b0;
   wire [15:0] tx_b_b = dac3mux[3] ? (dac3mux[1] ? (dac3mux[0] ? q_out_1 : i_out_1) : (dac3mux[0] ? q_out_0 : i_out_0)) : 16'b0;

   wire txsync = tx_sample_strobe;
   assign TXSYNC_A = txsync;
   assign TXSYNC_B = txsync;

   assign tx_a = txsync ? tx_b_a[15:2] : tx_a_a[15:2];
   assign tx_b = txsync ? tx_b_b[15:2] : tx_a_b[15:2];
`endif //  `ifdef TX_ON
   
   /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   // Receive Side
`ifdef RX_ON
   wire        rx_sample_strobe,strobe_decim,hb_strobe;
   wire [15:0] bb_rx_i0,bb_rx_q0,bb_rx_i1,bb_rx_q1,
	       bb_rx_i2,bb_rx_q2,bb_rx_i3,bb_rx_q3;

   wire loopback = settings[0];
   wire counter = settings[1];

   always @(posedge clk64)
     if(rx_dsp_reset)
       debug_counter <= #1 16'd0;
     else if(~enable_rx)
       debug_counter <= #1 16'd0;
     else if(hb_strobe)
       debug_counter <=#1 debug_counter + 16'd2;
   
   always @(posedge clk64)
     if(strobe_interp)
       begin
	  loopback_i_0 <= #1 ch0tx;
	  loopback_q_0 <= #1 ch1tx;
       end
   
   assign ch0rx = counter ? debug_counter : loopback ? loopback_i_0 : bb_rx_i0;
   assign ch1rx = counter ? debug_counter + 16'd1 : loopback ? loopback_q_0 : bb_rx_q0;
   assign ch2rx = bb_rx_i1;
   assign ch3rx = bb_rx_q1;
   assign ch4rx = bb_rx_i2;
   assign ch5rx = bb_rx_q2;
   assign ch6rx = bb_rx_i3;
   assign ch7rx = bb_rx_q3;

   wire [15:0] ddc0_in_i,ddc0_in_q,ddc1_in_i,ddc1_in_q,ddc2_in_i,ddc2_in_q,ddc3_in_i,ddc3_in_q;
   wire [31:0] rssi_0,rssi_1,rssi_2,rssi_3;
   
   adc_interface adc_interface(.clock(clk64),.reset(rx_dsp_reset),.enable(1'b1),
			       .serial_addr(serial_addr),.serial_data(serial_data),.serial_strobe(serial_strobe),
			       .rx_a_a(rx_a_a),.rx_b_a(rx_b_a),.rx_a_b(rx_a_b),.rx_b_b(rx_b_b),
			       .rssi_0(rssi_0),.rssi_1(rssi_1),.rssi_2(rssi_2),.rssi_3(rssi_3),
			       .ddc0_in_i(ddc0_in_i),.ddc0_in_q(ddc0_in_q),
			       .ddc1_in_i(ddc1_in_i),.ddc1_in_q(ddc1_in_q),
			       .ddc2_in_i(ddc2_in_i),.ddc2_in_q(ddc2_in_q),
			       .ddc3_in_i(ddc3_in_i),.ddc3_in_q(ddc3_in_q),.rx_numchan(rx_numchan) );
   
   rx_buffer rx_buffer
     ( .usbclk(usbclk),.bus_reset(rx_bus_reset),.reset(rx_dsp_reset),
       .reset_regs(rx_dsp_reset),
       .usbdata(usbdata_out),.RD(RD),.have_pkt_rdy(have_pkt_rdy),.rx_overrun(rx_overrun),
       .channels(rx_numchan),
       .ch_0(ch0rx),.ch_1(ch1rx),
       .ch_2(ch2rx),.ch_3(ch3rx),
       .ch_4(ch4rx),.ch_5(ch5rx),
       .ch_6(ch6rx),.ch_7(ch7rx),
       .rxclk(clk64),.rxstrobe(hb_strobe),
       .clear_status(clear_status),
       .serial_addr(serial_addr),.serial_data(serial_data),.serial_strobe(serial_strobe),
       .debugbus(rx_debugbus) );
   
 `ifdef RX_EN_0
   rx_chain #(`FR_RX_FREQ_0,`FR_RX_PHASE_0) rx_chain_0
     ( .clock(clk64),.reset(1'b0),.enable(enable_rx),
       .decim_rate(decim_rate),.sample_strobe(rx_sample_strobe),.decimator_strobe(strobe_decim),.hb_strobe(hb_strobe),
       .serial_addr(serial_addr),.serial_data(serial_data),.serial_strobe(serial_strobe),
       .i_in(ddc0_in_i),.q_in(ddc0_in_q),.i_out(bb_rx_i0),.q_out(bb_rx_q0),.debugdata(debugdata),.debugctrl(debugctrl));
 `else
   assign      bb_rx_i0=16'd0;
   assign      bb_rx_q0=16'd0;
 `endif
   
 `ifdef RX_EN_1
   rx_chain #(`FR_RX_FREQ_1,`FR_RX_PHASE_1) rx_chain_1
     ( .clock(clk64),.reset(1'b0),.enable(enable_rx),
       .decim_rate(decim_rate),.sample_strobe(rx_sample_strobe),.decimator_strobe(strobe_decim),.hb_strobe(),
       .serial_addr(serial_addr),.serial_data(serial_data),.serial_strobe(serial_strobe),
       .i_in(ddc1_in_i),.q_in(ddc1_in_q),.i_out(bb_rx_i1),.q_out(bb_rx_q1));
 `else
   assign      bb_rx_i1=16'd0;
   assign      bb_rx_q1=16'd0;
 `endif
   
 `ifdef RX_EN_2
   rx_chain #(`FR_RX_FREQ_2,`FR_RX_PHASE_2) rx_chain_2
     ( .clock(clk64),.reset(1'b0),.enable(enable_rx),
       .decim_rate(decim_rate),.sample_strobe(rx_sample_strobe),.decimator_strobe(strobe_decim),.hb_strobe(),
       .serial_addr(serial_addr),.serial_data(serial_data),.serial_strobe(serial_strobe),
       .i_in(ddc2_in_i),.q_in(ddc2_in_q),.i_out(bb_rx_i2),.q_out(bb_rx_q2));
 `else
   assign      bb_rx_i2=16'd0;
   assign      bb_rx_q2=16'd0;
 `endif

 `ifdef RX_EN_3
   rx_chain #(`FR_RX_FREQ_3,`FR_RX_PHASE_3) rx_chain_3
     ( .clock(clk64),.reset(1'b0),.enable(enable_rx),
       .decim_rate(decim_rate),.sample_strobe(rx_sample_strobe),.decimator_strobe(strobe_decim),.hb_strobe(),
       .serial_addr(serial_addr),.serial_data(serial_data),.serial_strobe(serial_strobe),
       .i_in(ddc3_in_i),.q_in(ddc3_in_q),.i_out(bb_rx_i3),.q_out(bb_rx_q3));
 `else
   assign      bb_rx_i3=16'd0;
   assign      bb_rx_q3=16'd0;
 `endif

`endif //  `ifdef RX_ON
   
   ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   // Control Functions

   wire [31:0] capabilities;
   assign      capabilities[7] =   `TX_CAP_HB;
   assign      capabilities[6:4] = `TX_CAP_NCHAN;
   assign      capabilities[3] =   `RX_CAP_HB;
   assign      capabilities[2:0] = `RX_CAP_NCHAN;


   serial_io serial_io
     ( .master_clk(clk64),.serial_clock(SCLK),.serial_data_in(SDI),
       .enable(SEN_FPGA),.reset(1'b0),.serial_data_out(SDO),
       .serial_addr(serial_addr),.serial_data(serial_data),.serial_strobe(serial_strobe),
       .readback_0({io_rx_a,io_tx_a}),.readback_1({io_rx_b,io_tx_b}),.readback_2(capabilities),.readback_3(32'hf0f0931a),
       .readback_4(rssi_0),.readback_5(rssi_1),.readback_6(rssi_2),.readback_7(rssi_3)
       );

   wire [15:0] reg_0,reg_1,reg_2,reg_3;
   master_control master_control
     ( .master_clk(clk64),.usbclk(usbclk),
       .serial_addr(serial_addr),.serial_data(serial_data),.serial_strobe(serial_strobe),
       .tx_bus_reset(tx_bus_reset),.rx_bus_reset(rx_bus_reset),
       .tx_dsp_reset(tx_dsp_reset),.rx_dsp_reset(rx_dsp_reset),
       .enable_tx(enable_tx),.enable_rx(enable_rx),
       .interp_rate(interp_rate),.decim_rate(decim_rate),
       .tx_sample_strobe(tx_sample_strobe),.strobe_interp(strobe_interp),
       .rx_sample_strobe(rx_sample_strobe),.strobe_decim(strobe_decim),
       .tx_empty(tx_empty),
       //.debug_0(rx_a_a),.debug_1(ddc0_in_i),
       .debug_0(tx_debugbus[15:0]),.debug_1(tx_debugbus[31:16]),
       .debug_2(rx_debugbus[15:0]),.debug_3(rx_debugbus[31:16]),
       .reg_0(reg_0),.reg_1(reg_1),.reg_2(reg_2),.reg_3(reg_3) );
   
   io_pins io_pins
     (.io_0(io_tx_a),.io_1(io_rx_a),.io_2(io_tx_b),.io_3(io_rx_b),
      .reg_0(reg_0),.reg_1(reg_1),.reg_2(reg_2),.reg_3(reg_3),
      .clock(clk64),.rx_reset(rx_dsp_reset),.tx_reset(tx_dsp_reset),
      .serial_addr(serial_addr),.serial_data(serial_data),.serial_strobe(serial_strobe));
   
   ////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
   // Misc Settings
   setting_reg #(`FR_MODE) sr_misc(.clock(clk64),.reset(rx_dsp_reset),.strobe(serial_strobe),.addr(serial_addr),.in(serial_data),.out(settings));

*/
endmodule // usrp_std
