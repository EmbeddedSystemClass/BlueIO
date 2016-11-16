import GetPut::*;
import Bluetiles::*;
import BS_Grass::*;
import ClientServer::*;

module mkTBBS_Grass(Empty);
	IfcBS_Grass u <- mkBS_Grass();

	Reg#(Int#(32)) counter_reg <- mkReg(0);

	rule testbench_counter;
		counter_reg <= counter_reg + 1;
	endrule
 

	// Test CMD Q -> CMD M
	rule testbench_putval_vir_turn_on(counter_reg == 8);
		u.bluetile_client.response.put (32'h00000005);	
	endrule

	rule testbench_putval_vir_turn_on_on(counter_reg == 9);
		u.bluetile_client.response.put (32'h00000004);	
	endrule

	rule testbench_putval(counter_reg == 10);
		u.bluetile_client.response.put (32'h00000003);	
	endrule 

	rule testbench_putval_2(counter_reg == 11);
		u.bluetile_client.response.put (32'h00000002);		
	endrule

	rule testbench_putval_vir_turn_on1(counter_reg == 12);
		u.bluetile_client.response.put (32'h00000001);	
	endrule

	rule testbench_putval_vir_turn_on_on1(counter_reg == 13);
		u.bluetile_client.response.put (32'h00000000);
	endrule	

	rule testbench_putval1(counter_reg == 14);
		u.bluetile_server0.request.put (32'h00000001);	
		u.bluetile_server1.request.put (32'h01000001);
		u.bluetile_server2.request.put (32'h02000001);
		u.bluetile_server3.request.put (32'h03000001);
	endrule 

	rule testbench_putval_21(counter_reg == 15);
		u.bluetile_server0.request.put (32'h00000002);	
		u.bluetile_server1.request.put (32'h01000002);
		u.bluetile_server2.request.put (32'h02000002);
		u.bluetile_server3.request.put (32'h03000002);	
	endrule 

	

	rule ddd(counter_reg < 20000);
		$display(u.bluetile_client.request.get());
	endrule 

endmodule
