package BS_Grass;

import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;
import BRAM::*;

Integer max_IO = 10;

interface IfcBS_Grass;
	method BlueClient bluetile_client;	// Receive messages from routers

	method BlueServer bluetile_server0;	// Send messages to IP cores
	method BlueServer bluetile_server1;	// Send messages to IP cores
	method BlueServer bluetile_server2;	// Send messages to IP cores
	method BlueServer bluetile_server3;	// Send messages to IP cores
	method BlueServer bluetile_server4;	// Send messages to IP cores
	method BlueServer bluetile_server5;	// Send messages to IP cores
	method BlueServer bluetile_server6;	// Send messages to IP cores
	method BlueServer bluetile_server7;	// Send messages to IP cores
	method BlueServer bluetile_server8;	// Send messages to IP cores
	method BlueServer bluetile_server9;	// Send messages to IP cores
endinterface

(* synthesize *)
module mkBS_Grass (IfcBS_Grass);
	FIFO#(BlueBits)		i_client <- mkSizedFIFO(10);
	FIFO#(BlueBits)		o_client <- mkSizedFIFO(10);

	FIFO#(BlueBits)		fifo_Grass_to_IP_cores[max_IO]; 
	FIFOF#(BlueBits)	fifo_IP_cores_to_Grass[max_IO];

	Reg#(BlueBits) 		header0  <- mkReg(0);
	Reg#(BlueBits) 		header1  <- mkReg(0);
	Reg#(BlueBits) 		header2  <- mkReg(0);

	Bit#(8) 			dest_IO = header2[7 : 0];
	Reg#(Bit#(8))		counter_payload <- mkReg(0);

	Reg#(Bit#(4))		id_arbiter <- mkReg(0);
	Reg#(Bit#(8))		counter_payload_back <- mkReg(0);

	for (Integer x = 0; x < max_IO; x = x + 1)
	begin
		fifo_Grass_to_IP_cores[x] <- mkSizedFIFO(4);
		fifo_IP_cores_to_Grass[x] <- mkSizedFIFOF(4);
	end

	Stmt fsm_BS_Grass_Receive = seq
		
		action
			header0 <= i_client.first();
			i_client.deq();
		endaction

		action
			header1 <= i_client.first();
			i_client.deq();
		endaction

		action
			header2 <= i_client.first();
			i_client.deq();
		endaction

		action
			counter_payload <= header0[7 : 0] - 2;
			fifo_Grass_to_IP_cores[dest_IO].enq(header0);
		endaction

		fifo_Grass_to_IP_cores[dest_IO].enq(header1);

		fifo_Grass_to_IP_cores[dest_IO].enq(header2);

		while (counter_payload > 0) action
			fifo_Grass_to_IP_cores[dest_IO].enq(i_client.first());
			i_client.deq();
			counter_payload <= counter_payload - 1;
		endaction
	endseq;

	Stmt fsm_BS_Grass_Sned =seq
		// Something can be sent
		if (fifo_IP_cores_to_Grass[id_arbiter].notEmpty == True) seq
			action
				fifo_IP_cores_to_Grass[id_arbiter].deq();
				counter_payload_back <= fifo_IP_cores_to_Grass[id_arbiter].first()[7 : 0];
				o_client.enq(fifo_IP_cores_to_Grass[id_arbiter].first());
			endaction

			while (counter_payload_back > 0) action
				o_client.enq(fifo_IP_cores_to_Grass[id_arbiter].first());
				fifo_IP_cores_to_Grass[id_arbiter].deq();
				counter_payload_back <= counter_payload_back - 1;
			endaction
		endseq

		else seq
			// Nothing to do
			noAction;
		endseq


		//	Scheduller
		if (id_arbiter >= pack(fromInteger(max_IO))[3 : 0] - 1) action
			id_arbiter <= 0;
		endaction

		else action
			id_arbiter <= id_arbiter + 1;
		endaction
	endseq;

	FSM fsm_BS_Grass_Receive_FSM <- mkFSM(fsm_BS_Grass_Receive);
	FSM fsm_BS_Grass_Sned_FSM <- mkFSM(fsm_BS_Grass_Sned);

	rule fsm_BS_Grass_Receive_FSM_rule;
		fsm_BS_Grass_Receive_FSM.start();
	endrule
	
  	rule fsm_BS_Grass_Sned_FSM_rule;
    	fsm_BS_Grass_Sned_FSM.start();
    endrule
		
	// Interfaces
	interface BlueClient bluetile_client;
		interface response = toPut(i_client);
		interface request = toGet(o_client);
	endinterface

	interface BlueServer bluetile_server0;
		interface request = toPut(fifo_IP_cores_to_Grass[0]);
	 	interface response = toGet(fifo_Grass_to_IP_cores[0]);
	endinterface

interface BlueServer bluetile_server1;
		interface request = toPut(fifo_IP_cores_to_Grass[1]);
	 	interface response = toGet(fifo_Grass_to_IP_cores[1]);
	endinterface

	interface BlueServer bluetile_server2;
		interface request = toPut(fifo_IP_cores_to_Grass[2]);
	 	interface response = toGet(fifo_Grass_to_IP_cores[2]);
	endinterface

	interface BlueServer bluetile_server3;
		interface request = toPut(fifo_IP_cores_to_Grass[3]);
	 	interface response = toGet(fifo_Grass_to_IP_cores[3]);
	endinterface


	interface BlueServer bluetile_server4;
		interface request = toPut(fifo_IP_cores_to_Grass[4]);
	 	interface response = toGet(fifo_Grass_to_IP_cores[4]);
	endinterface


	interface BlueServer bluetile_server5;
		interface request = toPut(fifo_IP_cores_to_Grass[5]);
	 	interface response = toGet(fifo_Grass_to_IP_cores[5]);
	endinterface

	interface BlueServer bluetile_server6;
		interface request = toPut(fifo_IP_cores_to_Grass[6]);
	 	interface response = toGet(fifo_Grass_to_IP_cores[6]);
	endinterface

	interface BlueServer bluetile_server7;
		interface request = toPut(fifo_IP_cores_to_Grass[7]);
	 	interface response = toGet(fifo_Grass_to_IP_cores[7]);
	endinterface

	interface BlueServer bluetile_server8;
		interface request = toPut(fifo_IP_cores_to_Grass[8]);
	 	interface response = toGet(fifo_Grass_to_IP_cores[8]);
	endinterface

	interface BlueServer bluetile_server9;
		interface request = toPut(fifo_IP_cores_to_Grass[9]);
	 	interface response = toGet(fifo_Grass_to_IP_cores[9]);
	endinterface
endmodule
endpackage