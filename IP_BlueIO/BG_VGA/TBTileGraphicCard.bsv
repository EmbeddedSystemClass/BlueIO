import GetPut::*;
import Bluetiles::*;
import TileVGAController::*;
import TileGraphicCard::*;
import ClientServer::*;

module mkTBTileGraphicCard(Empty);
	IfcTileGraphicCard gc <- mkTileGraphicCard();

	Reg#(Int#(32)) counter_reg <- mkReg(0);

	rule testbench_counter;
		counter_reg <= counter_reg + 1;
	endrule

	rule testbench_putval(counter_reg == 10);
		gc.bluetile.response.put (32'h02000002);
	endrule 

	rule testbench_putval_2(counter_reg == 11);
		gc.bluetile.response.put (32'h00002B2B);
	endrule 

	rule testbench_putval_3(counter_reg == 12);
		gc.bluetile.response.put (32'h00F0100B); // "!"
	endrule

	rule testbench_putval_4(counter_reg == 13);
		gc.bluetile.response.put (32'h02000002);
	endrule 

	rule testbench_putval_5(counter_reg == 14);
		gc.bluetile.response.put (32'h01012B2B);
	endrule 

	rule testbench_putval_6(counter_reg == 15);
		gc.bluetile.response.put (32'h02F2802B); // "H"
	endrule

	rule display;
		$display(gc.bluetile.request.get());
	endrule


endmodule
