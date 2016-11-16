#!/bin/bash

ln -nfs $BLUESPECDIR/Verilog bsverilog
bsc -p %/Prelude:%/Libraries:../ -u -verilog ../TileGraphicCard.bsv
../../util/generate_server_wrapper < BG_VGA.yml > BG_VGA.v
