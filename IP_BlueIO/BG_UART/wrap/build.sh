#!/bin/bash

ln -nfs $BLUESPECDIR/Verilog bsverilog
bsc -p %/Prelude:%/Libraries:../ -u -verilog ../BG_UART.bsv
../../util/generate_server_wrapper < BG_UART.yml > BG_UART.v
