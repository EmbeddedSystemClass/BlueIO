package TileFlash;

export IfcTileFlash(..);
export mkTileFlash;

import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;

interface IfcTileFlash;
    interface BlueClient bluetile_client;	// Communicate with routers
    interface BlueServer bluetile_server;	// Communicate with Vlab
endinterface


(* synthesize *)
module mkTileFlash (IfcTileFlash);
	FIFO#(BlueBits) 	i_client <- mkSizedFIFO(30);
	FIFO#(BlueBits) 	o_client <- mkSizedFIFO(30);
	FIFO#(BlueBits) 	i_server <- mkSizedFIFO(30);
	FIFO#(BlueBits) 	o_server <- mkSizedFIFO(30);

	// Instructions classification
	FIFO#(BlueBits)		i_page_man_client <- mkSizedFIFO(30);	// These two fifos are built for pages manger
	FIFO#(BlueBits)		o_page_man_client <- mkSizedFIFO(30);
	FIFO#(BlueBits)		i_page_rw_client <- mkSizedFIFO(270);	// These four fifos are built for pages read and write 
	FIFO#(BlueBits)		o_page_rw_client <- mkSizedFIFO(270);
	FIFO#(BlueBits)		i_page_rw_server <- mkSizedFIFO(270);
	FIFO#(BlueBits)		o_page_rw_server <- mkSizedFIFO(270);

	//	Input messages
	Reg#(BlueBits) 		rx_h0_reg <- mkReg(unpack(0));
	Reg#(BlueBits) 		rx_h1_reg <- mkReg(unpack(0));
	Reg#(PacketSize)	rx_counter_size_payload_reg <- mkReg(0);
	Bit#(8)				payload_size = rx_h0_reg[7 : 0] - 1;
	Bit#(8)				func_reqset = rx_h1_reg[7 : 0];		// "FF" for request sector
															// "EE" for give up sector
															// "DD" for write page
															// "CC" for read page
															// "88" for checks the owener of sectors
															// ......


	//	Input messages
	Reg#(BlueBits) 		rx_h0_reg_page_manger <- mkReg(unpack(0));
	Reg#(BlueBits) 		rx_h1_reg_page_manger <- mkReg(unpack(0));
	Bit#(8)				x_this_core_page_manger = rx_h0_reg_page_manger[31 : 24];
	Bit#(8)				y_this_core_page_manger = rx_h0_reg_page_manger[23 : 16];
	Bit#(8)				x_mesg_from_page_manger = rx_h1_reg_page_manger[31 : 24];
	Bit#(8) 			y_mesg_from_page_manger = rx_h1_reg_page_manger[23 : 16];
	Bit#(8)				func_reqset_page_manger = rx_h1_reg_page_manger[7 : 0];		// "FF" for request sector
																					// "EE" for give up sector
														
	Reg#(Bit#(8))		sector_status[1024];

	// Registers for "FF"
	Reg#(Bit#(32))		counter_i <- mkReg(0);
	Reg#(Bit#(1))		empty_sector_found <- mkReg(0);

	// Registers for "EE"
	Reg#(Bit#(32))		page_numb_giveup <- mkReg(0);

	/****************
	 *Initialization*
	 ****************/
	for (Integer i = 0; i < 1024; i = i + 1)
	begin
		 sector_status[i] <- mkReg(8'hFF);	// There's no one occupy the sector
	end

	/*****************
	 *Classify inputs*
	 *****************/
	Stmt fsm_inputs_clissification = seq
		action
			rx_h0_reg <= i_client.first();
			i_client.deq();
		endaction 

		action 
			rx_h1_reg <= i_client.first();
			i_client.deq();
		endaction

		rx_counter_size_payload_reg <= payload_size;

		// Classify Instructions
		if ((func_reqset == 8'hFF) || (func_reqset == 8'hEE)) seq // This is the pages manger's job
			i_page_man_client.enq(rx_h0_reg);
			i_page_man_client.enq(rx_h1_reg);

			while (rx_counter_size_payload_reg != 0) seq 
				i_page_man_client.enq(i_client.first());
				i_client.deq();
				rx_counter_size_payload_reg <= rx_counter_size_payload_reg - 1;
			endseq 
		endseq

		else seq
			if ((func_reqset == 8'hDD) || (func_reqset == 8'hCC)) seq // Just read or write
				i_page_rw_client.enq(rx_h0_reg);
				i_page_rw_client.enq(rx_h1_reg);

				while (rx_counter_size_payload_reg != 0) seq 
					i_page_rw_client.enq(i_client.first());
					i_client.deq();
					rx_counter_size_payload_reg <= rx_counter_size_payload_reg -1;
				endseq
			endseq

			else seq
				noAction; 
			endseq  
		endseq 
	endseq;

	/************************************************
	 *Pages Manager, including request, delete pages*
	 ************************************************/
	Stmt fsm_pages_manger = seq
		action 
			rx_h0_reg_page_manger <= i_page_man_client.first();
			i_page_man_client.deq();
		endaction

		action
			rx_h1_reg_page_manger <= i_page_man_client.first();
			i_page_man_client.deq();
		endaction

		if (func_reqset_page_manger == 8'hFF) seq // processors request for a sector
			action 		
				counter_i <= 0;	// Reset counter
				empty_sector_found <= 0; // Reset the searching flag
			endaction 

			while (empty_sector_found == 0) seq
				if ((sector_status[counter_i] == 8'hFF) || (counter_i == 1024))action 
					counter_i <= counter_i;
					empty_sector_found <= 1;
				endaction
				
				else action
					empty_sector_found <= 0;
					counter_i <= counter_i + 1;
				endaction 
			endseq 

			if (counter_i < 1024) seq // We found the unoccupied sector for you
				action 
					sector_status[counter_i] <= {x_mesg_from_page_manger[3:0], y_mesg_from_page_manger[3:0]};
					o_page_man_client.enq({x_mesg_from_page_manger, y_mesg_from_page_manger, 8'h00, 8'h02});
				endaction 
				o_page_man_client.enq({x_this_core_page_manger, y_this_core_page_manger, 8'hBB, 8'hBB}); // You got a sector
				o_page_man_client.enq(counter_i); // number of this sector 
			endseq

			else seq // We couldn't find the sector for you
				o_page_man_client.enq({x_mesg_from_page_manger, y_mesg_from_page_manger, 8'h00, 8'h01});
				o_page_man_client.enq({x_this_core_page_manger, y_this_core_page_manger, 8'h00, 8'hAA});	// You can't get a sector
			endseq
		endseq

		else seq
			if (func_reqset_page_manger == 8'hEE) seq // processors give up for a sector
				action 
					page_numb_giveup <= i_page_man_client.first();	// This is the number of sector, the processor wanna give up
					i_page_man_client.deq();
				endaction

				// An error correction
				if (sector_status[page_numb_giveup] == {x_mesg_from_page_manger[3:0], y_mesg_from_page_manger[3:0]}) seq // This processor actully has this sector
					sector_status[page_numb_giveup] <= 8'hFF;	// Now this page is free to be allocated again
				endseq 

				else seq // Processor has sent a wrong message
					sector_status[page_numb_giveup] <= sector_status[page_numb_giveup]; // U can't change it
				endseq
			endseq

			else seq
				noAction;
			endseq 
		endseq 
	endseq;

	FSM inputs_clissification_FSM <- mkFSM(fsm_inputs_clissification);
	FSM pages_manger_FSM <- mkFSM(fsm_pages_manger);

	rule pages_manger_FSM_rule;
		pages_manger_FSM.start();
	endrule 

	rule inputs_clissification_FSM_rule;
		inputs_clissification_FSM.start();
	endrule 

	rule output_rule;	// This is just a temple rule
		i_client.enq(o_page_man_client.first());
		o_page_man_client.deq();
	endrule 



	/************
	 *Interfaces*
	 ************/
	interface BlueServer bluetile_server;
        interface request = toPut(i_server);
        interface response = toGet(o_server);
    endinterface

	interface BlueClient bluetile_client;
        interface response = toPut(i_client);
        interface request = toGet(o_client);
    endinterface
endmodule

endpackage
