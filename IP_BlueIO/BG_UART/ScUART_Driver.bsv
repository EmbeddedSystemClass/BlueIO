package ScUART_Driver;

export IfcScUART_Driver(..);
export mkScUART_Driver;

import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;

import ScUART::*;

interface IfcScUART_Driver;
	interface BlueClient bluetile;	//	Receive messages from Bluetile System
	interface SerialWires serial;	//	Serial Ports of UART
endinterface

module mkScUART_Driver#(parameter Bit#(32) clk_freq, 
            parameter Bit#(32) baud_rate) (IfcScUART_Driver);

    FIFOF#(BlueBits) i <- mkSizedFIFOF(10);
	FIFOF#(BlueBits) o <- mkSizedFIFOF(10);
    IfcScUART u <- mkScUART(clk_freq, baud_rate);


	Stmt driver_BottomLayer = seq
	    par 
	    	while (True) action // Send from PC to UART
	    		u.enq(i.first()[7:0]);
	            i.deq();
	        endaction

	        while (True) action // Receive from UART to PC
	        	o.enq({24'h000000, u.first()});
	            u.deq();
	        endaction
	    endpar
	endseq;

    FSM driver_BottomLayerFSM <- mkFSM(driver_BottomLayer);

    rule fsm_driver_BottomLayer_rule;
        driver_BottomLayerFSM.start();
    endrule

    /************
	 *Interfaces*
	 ************/
	interface serial = u.serial;
    
    interface BlueClient bluetile;
        interface response = toPut(i);
        interface request = toGet(o);
    endinterface
endmodule

endpackage