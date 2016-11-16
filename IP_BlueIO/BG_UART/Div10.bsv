package Div10;

export mkDiv10;
export IfcDiv10(..);

import StmtFSM::*;
import FIFO::*;


interface IfcDiv10;
    method Action   enq(Bit#(32) data);
    method Action   deq();

    method Bit#(32) quotient();
    method Bit#(32) remainder();
    method Bit#(1)  done();
endinterface

module mkDiv10 (IfcDiv10);
    FIFO#(Bit#(32)) input_fifo <- mkSizedFIFO(10);
    Reg#(Bit#(32))  input_data <- mkReg(0);
    Reg#(Bit#(32))  quotient_reg <- mkReg(0);
    Reg#(Bit#(32))  remainder_reg <- mkReg(0);
    Reg#(Bit#(1))   done_reg <- mkReg(0);
    Wire#(Bit#(1))  deq_wr <- mkDWire(0);

    Stmt div10 = seq

        //  Get data
        action
            input_data <= input_fifo.first();
            input_fifo.deq();
            done_reg <= 0;
            quotient_reg <= 0;
            remainder_reg <= 0;
        endaction

        while(input_data >= 32'h0000000A) action
            input_data <= input_data - 32'h0000000A;
            quotient_reg <= quotient_reg + 1;
        endaction
        
        action
            remainder_reg <= input_data;
            done_reg <= 1;
        endaction

        while (deq_wr == 0) action
            done_reg <= 1;
        endaction

        done_reg <= 0;
    endseq;

    FSM div10FSM <- mkFSM(div10);

    rule fsm_div10_rule;
        div10FSM.start();
    endrule

    method Bit#(32) quotient();
        return quotient_reg;
    endmethod

    method Bit#(32) remainder();
        return remainder_reg;
    endmethod

    method Bit#(1)  done();
        return done_reg;
    endmethod
            
    method Action enq(Bit#(32) data);
        input_fifo.enq(data);
    endmethod

    method Action deq();
        deq_wr <= 1;
    endmethod
endmodule


endpackage

