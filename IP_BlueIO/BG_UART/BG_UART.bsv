package BG_UART;

export IfcBG_UART(..);
export mkBG_UART;

import FIFO::*;
import FIFOF ::*;
import GetPut::*;
import StmtFSM::*;
import Bluetiles::*;
import ClientServer::*;
import Connectable::*;

import ScUART::*;
import ScUART_Driver::*;
import ScUART_VMM::*;


interface IfcBG_UART;
	interface BlueClient bluetile;	//	Receive messages from Bluetile System
	interface SerialWires serial;	//	Serial Ports of UART
endinterface

(* synthesize *)
module mkBG_UART (IfcBG_UART);
	IfcScUART_Driver u <- mkScUART_Driver(100000000, 115200);
	IfcScUART_VMM	m <- mkScUART_VMM();

	/* Connect HW manager to UART */
    mkConnection(u.bluetile, m.bluetile_server);

    /************
	 *Interfaces*
	 ************/
	interface serial = u.serial;
    
    interface bluetile = m.bluetile_client;
endmodule

endpackage