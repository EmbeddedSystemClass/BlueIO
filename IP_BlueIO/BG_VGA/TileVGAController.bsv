package TileVGAController;

export VGAWires(..);
export IfcTileVGAController(..);
export mkTileVGAController;

import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;
import BRAM::*;

	
interface VGAWires;
	(* always_ready *)
    method Bit#(1) hsync();

    (* always_ready *)
    method Bit#(1) vsync();

    (* always_ready *)
    method Bit#(4) vga_red();

    (* always_ready *)
    method Bit#(4) vga_green();
    
    (* always_ready *)
    method Bit#(4) vga_blue();	
endinterface


interface IfcTileVGAController;
	method 	  Action   	enq(Bit#(32) cmd_para);
	method 	  Bit#(32)  first;	
	method 	  Action deq();
	interface VGAWires 	vga_pins;	// VGA pins
endinterface

module mkTileVGAController (IfcTileVGAController);
	// For Input fifo
	FIFO#(BlueBits) cmd_para_fifo <- mkSizedFIFO(300);
	FIFO#(BlueBits) out_fifo <- mkSizedFIFO(80);
	Reg#(Bit#(32))	cmd_crnt <- mkReg(0);
	Bit#(20)		cmd_crnt_coord_x = {8'b00000000, cmd_crnt[31:20]};
	Bit#(20)		cmd_crnt_coord_y = {8'b00000000, cmd_crnt[11: 0]};
	Bit#(1)			cmd_crnt_color	= cmd_crnt[16];

	// For outputs wires
	Wire#(Bit#(4))	vga_red_wr <- mkDWire(0);
	Wire#(Bit#(4))	vga_green_wr <- mkDWire(0);
	Wire#(Bit#(4))	vga_blue_wr <- mkDWire(0);

	// Clk signals
	Reg#(Bit#(1))	clk_25Mhz <- mkReg(0);
	Reg#(Bit#(32))	clk_25Mhz_counter <- mkReg(0);

	// Registers for row scan & field scan
	Reg#(Bit#(32))	hcounter <- mkReg(0);
	Reg#(Bit#(32))	vcounter <- mkReg(0);
	Reg#(Bool)		hcounter_ov <- mkReg(False);
	Reg#(Bool)		vcounter_ov <- mkReg(False);

	// Color transmission enable
	Reg#(Bit#(1))	data_oe	<- mkReg(0); 
	Bit#(32)		address = (vcounter - 34) *512 + (vcounter - 34) * 128 + hcounter - 142;

	// Video Memory
	// Addr Width, Data width
    BRAM_Configure cfg = defaultValue ;
    cfg.allowWriteResponseBypass = False;
	cfg.memorySize = 640*480 ; //new value for memorySize
	cfg.loadFormat = tagged Hex "video_memory.txt";
    BRAM2Port#(UInt#(20), Bit#(1)) video_mem <- mkBRAM2Server (cfg) ;
    Reg#(Bit#(1))	video_cache <- mkReg(0);

    //	Throughput Counter
    Reg#(Bit#(32))	counter_throughput <- mkReg(0);




    /******************************************************************
     *					 Video Memory Write 						  *
     ******************************************************************/
    Stmt fsm_video_mem_write = seq
    	if (cmd_para_fifo.first()[15:0] == 16'hEEEE) seq
    		counter_throughput	<= 0;
    	endseq

    	else seq
	    	if (cmd_para_fifo.first()[15:0] == 16'hFFFF) seq
	    		counter_throughput	<= counter_throughput + 1;
	    		out_fifo.enq({cmd_para_fifo.first()[31:16], 16'h0001});
	    		out_fifo.enq(counter_throughput); // This task finished
	    		cmd_para_fifo.deq();
	    	endseq

	    	else seq
	    		action
	    		cmd_crnt <= cmd_para_fifo.first();
	    		cmd_para_fifo.deq();
	    		endaction
	 
	    		video_mem.portA.request.put(BRAMRequest{write: True, 
	    	 											responseOnWrite:False,
	    	 											address: unpack(cmd_crnt_coord_y * 640 + cmd_crnt_coord_x),
	 	 												datain: cmd_crnt_color});
	    	endseq
	    endseq
    endseq;

    FSM video_mem_write_FSM <- mkFSM(fsm_video_mem_write);

    rule video_mem_write_FSM_rule;
        video_mem_write_FSM.start();
    endrule

    /******************x************************************************
     *					 Video Memory Read 	    					  *
     ******************************************************************/
    Stmt fsm_video_mem_cache = seq
   

     	if ((hcounter >= 142) && (hcounter < 782) && (vcounter >= 34) && (vcounter < 514) && (clk_25Mhz_counter == 0) && (clk_25Mhz == 0)) // prefetch
     	seq
     		
     		video_mem.portB.request.put(BRAMRequest{write: False,
     												responseOnWrite:False,
     												address: unpack(address[19:0]),
     												datain: 0}); 
     	endseq 
    	
     	action 
     		let video_cache_fast <- video_mem.portB.response.get(); 
     		video_cache <= pack(video_cache_fast);
     	endaction
    endseq;

    FSM video_mem_cache_FSM <- mkFSM(fsm_video_mem_cache);

    rule video_mem_cache_FSM_rule;
        video_mem_cache_FSM.start();
    endrule
    
	/*******************************************************************************************
	 *									VGA related settings								   *
	 *******************************************************************************************/
	// Freq Div
	rule freq_div_rule;
		if (clk_25Mhz_counter == 1)
		begin 
			clk_25Mhz <= ~clk_25Mhz;
			clk_25Mhz_counter <= 0;
		end

		else
		begin 
			clk_25Mhz <= clk_25Mhz;
			clk_25Mhz_counter <= clk_25Mhz_counter + 1;
		end
	endrule

	// Row and Field Scanning
	rule row_field_scan_rule;
		//	 Row Scanning
		if (hcounter == 799)
		begin
			// Rising edge of clk 25Mhz	
			if ((clk_25Mhz_counter == 1) && (clk_25Mhz == 0))
			begin
				 hcounter <= 0;
			end
			hcounter_ov <= True;
		end

		else
		begin
			// Rising edge of clk 25Mhz	
			if ((clk_25Mhz_counter == 1) && (clk_25Mhz == 0))
			begin
				 hcounter <= hcounter + 1;
			end
			hcounter_ov <= False;
		end

		// Field Scanning
		if (vcounter == 524)
		begin
			// Rising edge of clk 25Mhz
			if ((clk_25Mhz_counter == 1) && (clk_25Mhz == 0) && (hcounter == 799))
			begin 
				vcounter <= 0;
			end 
			vcounter_ov	<= True;
		end 
		else 
		begin
			// Rising edge of clk 25Mhz
			if ((clk_25Mhz_counter == 1) && (clk_25Mhz == 0) && (hcounter == 799))
			begin
				vcounter <= vcounter + 1;
			end 
			vcounter_ov <= False;
		end 
	endrule

	// Resolution Ratio Settings
	rule resolution_ratio_settings_rule;
		if( ((hcounter>=143) && (hcounter<783)) && ((vcounter>=34) && (vcounter<524)) ) // Maybe wrong
		begin
			data_oe <= 1;
		end

		else 
		begin
			data_oe <= 0; 
		end 
	endrule

	/*******************************************************************************************
	 *								Input & Output Interface		 						   *
	 *******************************************************************************************/
	method Action enq(Bit#(32) cmd_para);
		cmd_para_fifo.enq(cmd_para);
	endmethod

	method Bit#(32) first();
        return out_fifo.first();
    endmethod

    method Action deq();
        out_fifo.deq();
    endmethod


	interface VGAWires vga_pins;	// VGA pins
		method Bit#(1) hsync();
			Bit#(1)	return_value = 0;
			if (hcounter > 95)
			begin
				return_value = 1;
			end

			else 
			begin
				return_value = 0;
			end
			
            return return_value;
        endmethod

        method Bit#(1) vsync();
        	Bit#(1) return_value = 0;
        	if (vcounter > 1)
        	begin
        		return_value = 1;
        	end

        	else
        	begin
        		return_value = 0; 
        	end

        	return return_value;
        endmethod

        method Bit#(4) vga_red();
        	Bit#(4)	return_value = 4'b0000;
        	if ((data_oe == 1) && (video_cache == 1))
        	begin
        		return_value = 4'b1111;
        	end

        	else 
        	begin 
        		return_value = 4'b0000;
        	end 

        	return return_value;
        endmethod

        method Bit#(4) vga_green();
        	Bit#(4)	return_value = 4'b0000;
        	if ((data_oe == 1) && (video_cache == 1))
        	begin
        		return_value = 4'b1111;
        	end

        	else 
        	begin 
        		return_value = 4'b0000;
        	end 

        	return return_value;
        endmethod

        method Bit#(4) vga_blue();
        	Bit#(4)	return_value = 4'b0000;
        	if ((data_oe == 1) && (video_cache == 1))
        	begin
        		return_value = 4'b1111;
        	end

        	else 
        	begin 
        		return_value = 4'b0000;
        	end 

        	return return_value;
        endmethod
    endinterface

endmodule

endpackage

