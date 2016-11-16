package ScUART_VMM;

export IfcScUART_VMM(..);
export mkScUART_VMM;

import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;

import Div10::*;
import ScUART::*;

Integer max_user = 16;
Bit#(8)	x_uart = 4;
Bit#(8)	y_uart = 4;

interface IfcScUART_VMM;
	interface BlueClient bluetile_client;	//	Receive messages from Bluetile System
	interface BlueServer bluetile_server;	//	Send message to ScUART
endinterface


module mkScUART_VMM (IfcScUART_VMM);
	Reg#(Bool)			virtualization_enable <- mkReg(False);

	FIFO#(BlueBits)		i_client <- mkSizedFIFO(10);
	FIFO#(BlueBits)		o_client <- mkSizedFIFO(10);
	FIFOF#(BlueBits)	i_server <- mkSizedFIFOF(10);
	FIFO#(BlueBits)		o_server <- mkSizedFIFO(10);

	//	Input messages
	Reg#(BlueBits)		header0_reg	<- mkReg(0);
	Reg#(BlueBits)		header1_reg	<- mkReg(0);
	Bit#(8)				x_sender = header1_reg[31:24];
	Bit#(8)				y_sender = header1_reg[23:16];
	Bit#(8)				sender_message = (x_sender * x_uart) + y_sender;
	Bit#(16)			type_message = header1_reg[15:0];
	Bit#(8)				payload = header0_reg[7:0];
	Reg#(Bit#(8))		counter_payload	<- mkReg(0);
	Reg#(Bit#(64))		user_coordinates[max_user];
	Bit#(32)			user_coordinate_x[max_user];
	Bit#(32)			user_coordinate_y[max_user];
	Reg#(Bit#(32))		cursor_coordinate_x10 <- mkReg(0);
	Reg#(Bit#(32))		cursor_coordinate_x1 <- mkReg(0);
	Reg#(Bit#(32))		cursor_coordinate_y10 <- mkReg(0);
	Reg#(Bit#(32))		cursor_coordinate_y1 <- mkReg(0);

	//	Initialization Counter
	Reg#(BlueBits)		counter_row <- mkReg(0);
	Reg#(BlueBits)		counter_column <- mkReg(0);


	IfcDiv10 div_1 <- mkDiv10();
	IfcDiv10 div_2 <- mkDiv10();

	// Initilization
	for (Integer x = 0; x < max_user; x = x + 1)
	begin 
		user_coordinates[x] <- mkReg({32'h00000000, 32'h00000000});
		user_coordinate_x[x] = user_coordinates[x][63:32];
		user_coordinate_y[x] = user_coordinates[x][31:0];
	end

	Stmt fsm_VMM_tx = seq

		action
			header0_reg <= i_client.first();
			i_client.deq();
		endaction

		action
			header1_reg <= i_client.first();
			i_client.deq();
		endaction

		/*	
			1). Check if these messages are from the system manager;
			2).	Check if these messages are the virtualization instruction;
			3).	Check if these meeeages only have 1 payloard.
		*/
		if ((sender_message == 8'h00) && (type_message == 16'hFFFF) && (payload == 8'h01)) seq
			virtualization_enable <= True;
			
			/*	
				VMM stop and initialising the VMM to enable the function of Virtualization
			*/
			// Clear the screen:	CSI 2 J
			o_server.enq(32'h0000001B);
			o_server.enq(32'h0000005B);
			o_server.enq(32'h00000032);
			o_server.enq(32'h0000004A);
			o_server.enq(32'h00000000);

			// Initialize the coordinate:	CSI 1;1 H 
			o_server.enq(32'h0000001B);
			o_server.enq(32'h0000005B);
			o_server.enq(32'h00000031);
			o_server.enq(32'h0000003B);
			o_server.enq(32'h00000031);
			o_server.enq(32'h00000048);

			action
				o_server.enq(32'h00000000);
				counter_row <= 1;
				counter_column <= 1;
			endaction

			//	..
			//	Need draw a screen
			while (counter_column < 49) seq

				if (counter_column[1:0] ==  2'h01)  seq
					while (counter_row < 100) action
						o_server.enq(32'h0000002A);
						counter_row <= counter_row + 1;
					endaction
				endseq

				else seq
					while (counter_row < 100) action
						if ((counter_row == 1) || (counter_row == 99)) action
							o_server.enq(32'h0000002A);
							counter_row <= counter_row + 1;
						endaction

						else action
							o_server.enq(32'h00000020);
							counter_row <= counter_row + 1;
						endaction
					endaction
				endseq
	
				o_server.enq(32'h0000000A);
				o_server.enq(32'h0000000D);
								
				action
					counter_row <= 1;	
					counter_column <= counter_column + 1;
				endaction
			endseq
		endseq

		else seq
			if ((sender_message == 8'h00) && (type_message == 16'hEEEE) && (payload == 8'h01)) seq
				virtualization_enable <= False;

				/*	
					VMM stop and initialising the VMM to disable the function of Virtualization
				*/
				// Clear the screen:	
				//		CSI 2 J
				o_server.enq(32'h0000001B);
				o_server.enq(32'h0000005B);
				o_server.enq(32'h00000032);
				o_server.enq(32'h0000004A);
				o_server.enq(32'h00000000);

				// Initialize the coordinate:	
				//		CSI 1;1 H 
				o_server.enq(32'h0000001B);
				o_server.enq(32'h0000005B);
				o_server.enq(32'h00000031);
				o_server.enq(32'h0000003B);
				o_server.enq(32'h00000031);
				o_server.enq(32'h00000048);
				o_server.enq(32'h00000000);
			endseq

			else action
				noAction;
			endaction
		endseq

		counter_payload	<= payload - 1;

		while (counter_payload != 0) seq
			if (virtualization_enable == False) action
				o_server.enq(i_client.first());
				i_client.deq();
			endaction 

			else seq
				/*	
					Step 1:
					Move the curosr to its coordinates
				*/

				par 
					if (div_1.done == 0) seq
						div_1.enq(user_coordinate_x[sender_message] + 3);

						while (div_1.done == 0) action
							noAction;
						endaction

						action
							cursor_coordinate_x10 <= div_1.quotient();
							cursor_coordinate_x1 <= div_1.remainder();
							div_1.deq();
						endaction
					endseq
					
					if (div_2.done == 0) seq
						div_2.enq(user_coordinate_y[sender_message] + {24'h000000, (sender_message * 4 + 2)});

						while (div_2.done == 0) action
							noAction;
						endaction

						action
							cursor_coordinate_y10 <= div_2.quotient();
							cursor_coordinate_y1 <= div_2.remainder();
							div_2.deq();
						endaction
					endseq
				endpar
				
				// Move the curosr to its physical coordinates: 	
				//		CSI y;x H 
				o_server.enq(32'h0000001B);
				o_server.enq(32'h0000005B);
				o_server.enq(32'h00000030 + cursor_coordinate_y10);	//	Convert to Char
				o_server.enq(32'h00000030 + cursor_coordinate_y1);	//	Convert to Char
				o_server.enq(32'h0000003B);
				o_server.enq(32'h00000030 + cursor_coordinate_x10);	//	Convert to Char
				o_server.enq(32'h00000030 + cursor_coordinate_x1);	//	Convert to Char
				o_server.enq(32'h00000048);


				/*	
					Step 2:
					Print out the new character
					
					if char == 0x0D || 0x0A, then
						print out nothing
					else
						print out the char
				*/
				if ((i_client.first() == 32'h0000000D) || (i_client.first() == 32'h0000000A)) action
					//	 Donot need "o_server.enq(i_client.first())";
					noAction;
				endaction 

				else action
					o_server.enq(i_client.first());
				endaction

				/*	
					Step 3:
					Calculate the current coordinates
				
					if char == 0x0D	||	0X0A, then
						"(x = 0; y = y + 1)"
					else
						"(x = x + 1; y = y)"
				*/
				if ((i_client.first() == 32'h0000000D) || (i_client.first() == 32'h0000000A)) seq
					user_coordinates[sender_message][63:32] <= 0;	// X
					user_coordinates[sender_message][31:0] <= user_coordinates[sender_message][31:0] + 1;	// Y
					i_client.deq();
				endseq

				else action
					user_coordinates[sender_message][63:32] <= user_coordinates[sender_message][63:32] + 1;	// X
					i_client.deq();
				endaction

 
				/*	
					Step 4:
					Check the current coordinates
					
					if "x > 90", then
						"(x = 0; y = y + 1)"
					if  "y > 5", then
						"(x = 0; y = 0)"
				*/
				if (user_coordinate_x[sender_message] > 90) seq
					user_coordinates[sender_message][63:32] <= 0;
					user_coordinates[sender_message][31:0] <= user_coordinates[sender_message][31:0] + 1;
				endseq

				else action
					noAction;
				endaction

				if (user_coordinate_y[sender_message] > 3) seq
					user_coordinates[sender_message][63:32] <= 0;
					user_coordinates[sender_message][31:0] <= 0;
				endseq

				else action
					noAction;
				endaction
			endseq

			counter_payload <= counter_payload - 1;
		endseq
	endseq;

	Stmt fsm_VMM_rx = seq

		if (i_server.notEmpty == True) seq
			o_client.enq({x_sender, y_sender, 16'h0001});
			o_client.enq({x_uart, y_uart, 16'h0000});

			action
				o_client.enq(i_server.first());
				i_server.deq();
			endaction
		endseq
	endseq;


	FSM fsm_VMM_txFSM <- mkFSM(fsm_VMM_tx);
    FSM fsm_VMM_rxFSM <- mkFSM(fsm_VMM_rx);

    rule fsm_VMM_txFSM_rule;
        fsm_VMM_txFSM.start();
    endrule

    rule fsm_VMM_rxFSM_rule;
        fsm_VMM_rxFSM.start();
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
