/******************************************************************************
*
* Copyright (C) 2014 - 2015 Xilinx, Inc. All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* Use of the Software is limited solely to applications:
* (a) running on a Xilinx device, or
* (b) that interact with a Xilinx device through a bus or interconnect.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
* XILINX  BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF
* OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
* SOFTWARE.
*
* Except as contained in this notice, the name of the Xilinx shall not be used
* in advertising or otherwise to promote the sale, use or other dealings in
* this Software without prior written authorization from Xilinx.
*
******************************************************************************/
/*****************************************************************************/
/**
*
* @file usleep.c
*
* This function provides a microsecond delay using the Global Timer register in
* the ARM Cortex R5 MP core.
*
* <pre>
* MODIFICATION HISTORY:
*
* Ver   Who      Date     Changes
* ----- -------- -------- -----------------------------------------------
* 5.00 	pkp  02/20/14 First release
* </pre>
*
******************************************************************************/
/***************************** Include Files *********************************/

#include "sleep.h"
#include "xtime_l.h"
#include "xparameters.h"
#include "xil_types.h"
#include "xpseudo_asm.h"
#include "xreg_cortexr5.h"

/* Global Timer is always clocked at half of the CPU frequency */
#define COUNTS_PER_USECOND  25U

/*****************************************************************************/
/**
*
* This API gives a delay in microseconds
*
* @param	useconds requested
*
* @return	0 if the delay can be achieved, -1 if the requested delay
*		is out of range
*
* @note		None.
*
****************************************************************************/

s32 usleep(u32 useconds)
{
	XTime tEnd, tCur;
	/*disable ttc timer*/
	Xil_Out32(TTC3_BASEADDR + 0x0000000CU,0x1U);
	/*set prescale value*/
	Xil_Out32(TTC3_BASEADDR + 0x00000000U, 0x000001U);
	/*write interval value to register*/
	Xil_Out32(TTC3_BASEADDR + 0x00000024U,0xFFFFFFFFU);
	/*write match value to register*/
	Xil_Out32(TTC3_BASEADDR + 0x00000030U,0xFFFFFFFFU);
	/* Enable ttc Timer */
	Xil_Out32(TTC3_BASEADDR + 0x0000000CU,0x1AU);

	XTime_GetTime(&tCur);

	tEnd  = tCur + (((XTime) useconds) * (COUNTS_PER_USECOND));
	do
	{
	    XTime_GetTime(&tCur);
	} while (tCur < tEnd);

	/* Disable ttc Timer */
	Xil_Out32(TTC3_BASEADDR + 0x0000000CU, Xil_In32(TTC3_BASEADDR + 0x0000000CU) | 0x00000001U);

	return 0;
}
