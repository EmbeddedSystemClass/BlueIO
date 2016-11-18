#ifndef __BS_uart_H_
#define __BS_uart_H_

#include "BS_NoC.h"
#include "xil_types.h"
#include "xil_io.h"
#include <stdio.h>
#include "Config.h"



void BS_uart_virtualization_on();
void BS_printf(char *c);
void printhex2(unsigned x, unsigned size);
void printdec(unsigned x);


#endif
