import GetPut::*;
import Bluetiles::*;
import Div10::*;
import ClientServer::*;

module mkTBDiv10(Empty);
	IfcDiv10 u <- mkDiv10();

	Reg#(Int#(32)) counter_reg <- mkReg(0);

	rule testbench_counter;
		counter_reg <= counter_reg + 1;
	endrule
 

	// Test CMD Q -> CMD M
	rule testbench_putval_vir_turn_on(counter_reg == 8);
		u.enq (264800);	
	endrule

	rule testbench_putval_vir_turn_on_on(counter_reg == 9);
		u.enq (512);	
	endrule

	rule testbench_putval_21(counter_reg == 27000);
		u.deq();
	endrule 

	

	rule ddd(counter_reg < 20000);
		$display(u.quotient());
	endrule 

endmodule
