#ifndef __NoC_Driver_H_
#define __NoC_Driver_H_

#include <stdio.h>
#include "platform.h"
#include "xllfifo.h"
#include "xstatus.h"
#include "xparameters.h"

#define CPU_X		1
#define CPU_Y		2

#define FIFO_DEV_BT	   			XPAR_ZYNQTOPLEVEL_BT_FIFO_DEVICE_ID

int XLlFifoConfig(XLlFifo *InstancePtr, u16 DeviceId);
int XLlFifoSend(XLlFifo *InstancePtr, u32 *Data, u32 Bytes);
int XLlFifoReceive (XLlFifo *InstancePtr, u32* DestinationAddr);
int if_mesg_coming (XLlFifo *InstancePtr);
int sys_func_testing ();
void NoC_init();
void bt_tx_mb(u32 mesg);

u32 uart_cmds[5000];

XLlFifo FifoBT, FifoMangerUART, FifoMangerFlash;


#endif
