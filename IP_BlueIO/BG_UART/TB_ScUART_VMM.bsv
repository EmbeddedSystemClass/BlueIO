import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;

import ScUART_VMM::*;


module mkTBScUART_Driver(Empty);
	IfcScUART_VMM u <- mkScUART_VMM();

	Reg#(Int#(32)) counter_reg <- mkReg(0);

	rule testbench_counter;
		counter_reg <= counter_reg + 1;
	endrule
 
	
	Stmt testbench = seq
		/*	
			1). Test unprivileged control
		*/
		u.bluetile_client.response.put (32'h10100001);
		u.bluetile_client.response.put (32'h0101FFFF);	
	
		/*
			2).	Test Un-virtualized "printf"
		*/
		// Headers - useless
		u.bluetile_client.response.put (32'h10100002);
		u.bluetile_client.response.put (32'h0000FFFF);	
		u.bluetile_client.response.put (32'h0000002B);	//	Printf "0x2B"

		/*	
			3).	Test virtualization enable
		*/
		// Headers
		u.bluetile_client.response.put (32'h10100001);
		u.bluetile_client.response.put (32'h0000FFFF);


		/*
			4).	Test Virtualized "printf" - from (1, 1)
		*/
		u.bluetile_client.response.put (32'h00000005);
		u.bluetile_client.response.put (32'h0101FFFF);
		u.bluetile_client.response.put (32'h0000002B);	//	Printf "0x2B"
		u.bluetile_client.response.put (32'h0000000D);	//	Printf "\n"
		u.bluetile_client.response.put (32'h00000005);	//	Printf "0x05"
		u.bluetile_client.response.put (32'h00000050);	//	Printf "0x50"
		
		/*
			5).	Test Virtualized "printf" - from (2, 2)
		*/
		u.bluetile_client.response.put (32'h00000005);
		u.bluetile_client.response.put (32'h0101FFFF);
		u.bluetile_client.response.put (32'h00000033);	//	Printf "0x2B"
		u.bluetile_client.response.put (32'h0000000D);	//	Printf "\n"
		u.bluetile_client.response.put (32'h00000044);	//	Printf "0x05"
		u.bluetile_client.response.put (32'h00000055);	//	Printf "0x50"

		/*
			5).	Test Virtualized "printf" - from (1, 1)
		*/
		u.bluetile_client.response.put (32'h00000005);
		u.bluetile_client.response.put (32'h0101FFFF);
		u.bluetile_client.response.put (32'h00000001);	//	Printf "0x2B"
		u.bluetile_client.response.put (32'h0000000D);	//	Printf "\n"
		u.bluetile_client.response.put (32'h000000F0);	//	Printf "0x05"
		u.bluetile_client.response.put (32'h00000080);	//	Printf "0x50"
	endseq;

	FSM fsm_testbench <- mkFSM(testbench);

	rule fsm_testbench_rule(counter_reg == 200);
        fsm_testbench.start();
    endrule

	rule ddd(counter_reg < 20000000);
		$display(u.bluetile_server.response.get());
	endrule 

endmodule