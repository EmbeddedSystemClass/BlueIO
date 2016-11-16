package TileGraphicCard;

export IfcTileGraphicCard(..);
export mkTileGraphicCard;

import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import TileVGAController::*;
import Bluetiles::*;
import ClientServer::*;
import Font::*;

interface IfcTileGraphicCard;
    interface VGAWires vga_pins;
    interface BlueClient bluetile;
endinterface

(* synthesize *)
module mkTileGraphicCard (IfcTileGraphicCard);
	// Interfaces
	FIFOF#(BlueBits) 		i <- mkSizedFIFOF(270);
	FIFOF#(BlueBits) 		o <- mkSizedFIFOF(80);
	IfcTileVGAController 	vga <- mkTileVGAController();
	FIFOF#(BlueBits) 		instr_storage[size_x_NoC][size_y_NoC];

	// Bluetiles headers
	Reg#(BlueBits) 			bluetiles_header1 <- mkReg(0);
	Reg#(BlueBits)			bluetiles_header2 <- mkReg(0);
	Reg#(BlueBits)			bluetiles_context <- mkReg(0);
	Reg#(Bit#(8))			size_payload <- mkReg(0);
	Bit#(8)					crnt_mesge_inp_x_axis = bluetiles_header2[31 : 24];
	Bit#(8) 				crnt_mesge_inp_y_axis = bluetiles_header2[23 : 16];
	Bit#(8)					character = bluetiles_context[19:12];
	Bit#(32)				start_x = {20'h00000, bluetiles_context[31:20]};
	Bit#(32)				start_y = {20'h00000, bluetiles_context[11:0]};

	// Advanced registers
	Reg#(BlueBits)			counter_i <- mkReg(0);
	Reg#(BlueBits)			counter_j <- mkReg(0);
	Reg#(Bit#(8))			counter_k <- mkReg(0);
	Reg#(Bit#(8))			temp <- mkReg(0);
	Reg#(Bit#(8))			temp2 <- mkReg(0);
	Reg#(Bit#(32))			cmd <- mkReg(0);
	Reg#(Bit#(32))			xx <- mkReg(0);
	Reg#(Bit#(32))			yy <- mkReg(0);

	// Schedulling stuffs
	Reg#(Bit#(1))		user_existed_reg <- mkReg(0);
	Wire#(Bit#(1))  	instr_storage_status_wr[size_x_NoC][size_y_NoC];	// Wire Bank
	Reg#(Bit#(16))		crnt_user_coordinate_reg <- mkReg(0);
	Bit#(8)				crnt_user_coordinate_x = crnt_user_coordinate_reg[15:8];
	Bit#(8)				crnt_user_coordinate_y = crnt_user_coordinate_reg[7:0];


	// Initilization
	for (Integer y_axis = 0; y_axis < size_y_NoC; y_axis = y_axis + 1)	// x_axis from 0 => 4
	begin 
		for (Integer x_axis = 0; x_axis < size_x_NoC; x_axis = x_axis + 1)	// y_axis from 0 => 4
		begin
			instr_storage[x_axis][y_axis] <- mkSizedFIFOF(300);
			instr_storage_status_wr[x_axis][y_axis] <- mkDWire(0);
		end 
	end

	/*******************************************************************************************
	 *										Inputs		 									   *
	 *******************************************************************************************/
	Stmt fsm_gpu_input = seq
		// Initial Configuration
		counter_i <= 0; // Reset
		while (counter_i != 480) action
			instr_storage[0][0].enq(32'h140FF000|counter_i);
			counter_i <= counter_i + 1;
		endaction 
		counter_i <= 0; // Reset
		while (counter_i != 640) action 
			instr_storage[0][0].enq(32'h000FF0F0|(counter_i<<20));
			counter_i <= counter_i + 1;
		endaction
		counter_i <= 0; // Reset

		while (True) seq
			action 
				bluetiles_header1 <= i.first();
				i.deq();
			endaction 

			action
				bluetiles_header2 <= i.first();
				i.deq(); 
			endaction


			action 
				size_payload <= bluetiles_header1[7:0] - 1;
				counter_k <= 0;
			endaction

			// Loops - load all the characters
			while (counter_k != size_payload) seq
				action 
					bluetiles_context <= i.first();
					i.deq();
				endaction

				action 
					bluetiles_context[31:20] <= bluetiles_context[31:20] + ({4'b0000,counter_k} * 8);
					counter_k <= counter_k + 1;
				endaction

				while (start_x > 307)
				seq
					bluetiles_context[31:20] <= bluetiles_context[31:20] - 307;
					bluetiles_context[11:0]	<= bluetiles_context[11:0] + 15;
				endseq 

				action 
					counter_i <= 0;
					counter_j <= 0;
				endaction
				// Start loop
				while (counter_j != 12)seq
					action			
						counter_j <= counter_j + 1;
						temp <=	font[character][counter_j];
					endaction

					while (counter_i != 8)seq
						action 
							temp2 <= temp & 8'h01;
							counter_i <= counter_i + 1;
							temp <= temp >> 1;
							xx <= start_x + counter_i;
							yy <= start_y + counter_j;
						endaction

						action 
						if (temp2 == 8'h01) 
						begin
							if ((crnt_mesge_inp_x_axis == 0) && (crnt_mesge_inp_y_axis == 0))
								cmd <= 32'h000FF000|(xx<<20)|(yy);
							if ((crnt_mesge_inp_x_axis == 1) && (crnt_mesge_inp_y_axis == 0))
								cmd <= 32'h000FF000|((xx+320)<<20)|(yy);
							if ((crnt_mesge_inp_x_axis == 0) && (crnt_mesge_inp_y_axis == 1))
								cmd <= 32'h000FF000|(xx<<20)|(yy+240);
							if ((crnt_mesge_inp_x_axis == 1) && (crnt_mesge_inp_y_axis == 1))
								cmd <= 32'h000FF000|((xx+320)<<20)|(yy+240);
						end 
						else
						begin  
							if ((crnt_mesge_inp_x_axis == 0) && (crnt_mesge_inp_y_axis == 0))
								cmd <= 32'h00000000|(xx<<20)|(yy);
							if ((crnt_mesge_inp_x_axis == 1) && (crnt_mesge_inp_y_axis == 0))
								cmd <= 32'h00000000|((xx+320)<<20)|(yy);
							if ((crnt_mesge_inp_x_axis == 0) && (crnt_mesge_inp_y_axis == 1))
								cmd <= 32'h00000000|(xx<<20)|(yy+240);
							if ((crnt_mesge_inp_x_axis == 1) && (crnt_mesge_inp_y_axis == 1))
								cmd <= 32'h00000000|((xx+320)<<20)|(yy+240);
						end 
						endaction

						instr_storage[crnt_mesge_inp_x_axis][crnt_mesge_inp_y_axis].enq(cmd);
					endseq
						counter_i <= 0;
				endseq
				// End loop
				instr_storage[crnt_mesge_inp_x_axis][crnt_mesge_inp_y_axis].enq({bluetiles_header2[31:16],16'hFFFF});
				
				action // Reset counters
					counter_i <= 0;
					counter_j <= 0;
				endaction
			endseq 
		endseq
	endseq; 

	/*******************************************************************************************
	 *										Schedulling		 								   *
	 *******************************************************************************************/
	for (Integer y_axis = size_y_NoC - 1; y_axis >= 0; y_axis = y_axis - 1)
	begin 

		for (Integer x_axis = size_x_NoC - 1; x_axis >= 0; x_axis = x_axis - 1)
		begin 

			rule instr_storage_notEmpty_rule (instr_storage[x_axis][y_axis].notEmpty == True);
				instr_storage_status_wr[x_axis][y_axis] <= 1;
			endrule

			rule instr_storage_Empty_rule (instr_storage[x_axis][y_axis].notEmpty == False);
				instr_storage_status_wr[x_axis][y_axis]	<= 0;
			endrule
		end
	end

	rule scheuller_next_user;
		Bit#(16)	crnt_user_coordinate = 0;
		Bit#(1)		user_existed = 0;
		for (Integer y_axis = size_y_NoC - 1; y_axis >= 0; y_axis = y_axis - 1)	// Notice can not use y_axis == 0
		begin 

			for (Integer x_axis = size_x_NoC - 1; x_axis >= 0; x_axis = x_axis -1)
			begin 

				if (instr_storage_status_wr[x_axis][y_axis] == 1)
				begin
					crnt_user_coordinate[15 : 8] = pack(fromInteger(x_axis))[7:0];	// x
					crnt_user_coordinate[7	: 0] = pack(fromInteger(y_axis))[7:0];	// y
					user_existed = 1;
				end	 
			end 
		end

		crnt_user_coordinate_reg <=	crnt_user_coordinate;
		user_existed_reg <= user_existed;
	endrule
	/*******************************************************************************************
	 *					Above this line, the schedulling finished !!						   *
	 *******************************************************************************************
	 *								    End schedulling 		 							   *
	 *******************************************************************************************/

	/*******************************************************************************************
	 *										Outputs...		 								   *
	 *******************************************************************************************/
	Stmt fsm_gpu_output = seq
		while (user_existed_reg == 1)seq  // Somthing is waiting ot come out...
			/***************************
		 	 *		Outputs	!!!		   *
		 	 ***************************/
	        vga.enq(instr_storage[crnt_user_coordinate_x][crnt_user_coordinate_y].first());
	        instr_storage[crnt_user_coordinate_x][crnt_user_coordinate_y].deq();
		endseq
		noAction; // Synchonize with the scheduller
		noAction; // Synchonize with the scheduller
		noAction; // Synchonize with the scheduller
		noAction; // Synchonize with the scheduller
	endseq;

	FSM gpu_output_FSM <- mkFSM(fsm_gpu_output);
	FSM gpu_input_FSM <- mkFSM(fsm_gpu_input);

	rule graphic_card_FSM_rule;
        gpu_input_FSM.start();
    endrule

    rule gpu_input_FSM_rule;
    	gpu_output_FSM.start();
    endrule 

    rule return_finish;
    	o.enq(vga.first());
    	vga.deq();
    endrule

	interface vga_pins = vga.vga_pins;
	interface BlueClient bluetile;
        interface response = toPut(i);
        interface request = toGet(o);
    endinterface

endmodule

endpackage