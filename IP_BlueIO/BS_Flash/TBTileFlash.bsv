import GetPut::*;
import Bluetiles::*;
import TileFlash::*;
import ClientServer::*;

module mkTBTileFlash(Empty);
	IfcTileFlash f <- mkTileFlash();

	Reg#(Int#(32)) counter_reg <- mkReg(0);

	rule testbench_counter;
		counter_reg <= counter_reg + 1;
	endrule

	/* Test Pages (Sector) Request */ // From proc (1,1)
	rule testbench_putval_vir_turn_on(counter_reg == 5);
		f.bluetile_client.response.put (32'h02020001);
	endrule

	rule testbench_putval_vir_turn_on_on(counter_reg == 6);
		f.bluetile_client.response.put (32'h0101FFFF);	// Request sector
	endrule

	/* Test Pages (Sector) Request */ // From proc (3,3)
	rule testbench_putval(counter_reg == 10);
		f.bluetile_client.response.put (32'h02020001);
	endrule 

	rule testbench_putval_2(counter_reg == 11);
		f.bluetile_client.response.put (32'h0303FFFF);
	endrule 


	rule forth_display(counter_reg < 20000);
		$display(f.bluetile_client.request.get());
	endrule 
endmodule
