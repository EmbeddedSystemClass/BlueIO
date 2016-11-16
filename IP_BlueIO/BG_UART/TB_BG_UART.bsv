import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;

import ScUART::*;
import BG_UART::*;


module mkTBScUART_Driver(Empty);
	IfcBG_UART u <- mkBG_UART();

	Reg#(Int#(32)) counter_reg <- mkReg(0);

	rule testbench_counter;
		counter_reg <= counter_reg + 1;
	endrule
 
	
	Stmt testbench = seq
		/*	
			1). Test unprivileged control
		*/
		u.bluetile.response.put (32'h10100002);
		u.bluetile.response.put (32'h0101CCCC);	
		u.bluetile.response.put (32'h0000002B);	//	Printf "0x50"
	endseq;

	FSM fsm_testbench <- mkFSM(testbench);

	rule fsm_testbench_rule(counter_reg == 200);
        fsm_testbench.start();
    endrule

	rule ddd(counter_reg < 20000000);
		$display(u.serial.txd());
	endrule 

endmodule