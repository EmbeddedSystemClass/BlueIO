import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;

import Div10::*;
import ScUART::*;
import ScUART_Driver::*;


module mkTBScUART_Driver(Empty);
	IfcScUART_Driver u <- mkScUART_Driver(100000000, 11800);

	Reg#(Int#(32)) counter_reg <- mkReg(0);

	rule testbench_counter;
		counter_reg <= counter_reg + 1;
	endrule
 
	// Test CMD Q -> CMD M
	rule testbench_putval_vir_turn_on(counter_reg == 8);
		u.bluetile.response.put (32'h00000050);	
	endrule

	rule testbench_putval_vir_turn_on_on(counter_reg == 9);
		u.bluetile.response.put (32'h00000005);	
	endrule

	rule testbench_putval_21(counter_reg == 15);
		u.bluetile.response.put (32'h00000055);	
	endrule 

	

	rule ddd(counter_reg < 20000000);
		$display(u.serial.txd());
	endrule 

endmodule