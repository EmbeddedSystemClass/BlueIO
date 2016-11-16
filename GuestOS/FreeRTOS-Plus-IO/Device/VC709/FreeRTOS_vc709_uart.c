/*
 * FreeRTOS+IO V1.0.1 (C) 2012 Real Time Engineers ltd.
 *
 * FreeRTOS+IO is an add-on component to FreeRTOS.  It is not, in itself, part 
 * of the FreeRTOS kernel.  FreeRTOS+IO is licensed separately from FreeRTOS, 
 * and uses a different license to FreeRTOS.  FreeRTOS+IO uses a dual license
 * model, information on which is provided below:
 *
 * - Open source licensing -
 * FreeRTOS+IO is a free download and may be used, modified and distributed
 * without charge provided the user adheres to version two of the GNU General
 * Public license (GPL) and does not remove the copyright notice or this text.
 * The GPL V2 text is available on the gnu.org web site, and on the following
 * URL: http://www.FreeRTOS.org/gpl-2.0.txt
 *
 * - Commercial licensing -
 * Businesses and individuals who wish to incorporate FreeRTOS+IO into
 * proprietary software for redistribution in any form must first obtain a low
 * cost commercial license - and in-so-doing support the maintenance, support
 * and further development of the FreeRTOS+IO product.  Commercial licenses can
 * be obtained from http://shop.freertos.org and do not require any source files
 * to be changed.
 *
 * FreeRTOS+IO is distributed in the hope that it will be useful.  You cannot
 * use FreeRTOS+IO unless you agree that you use the software 'as is'.
 * FreeRTOS+IO is provided WITHOUT ANY WARRANTY; without even the implied
 * warranties of NON-INFRINGEMENT, MERCHANTABILITY or FITNESS FOR A PARTICULAR
 * PURPOSE. Real Time Engineers Ltd. disclaims all conditions and terms, be they
 * implied, expressed, or statutory.
 *
 * 1 tab == 4 spaces!
 *
 * http://www.FreeRTOS.org
 * http://www.FreeRTOS.org/FreeRTOS-Plus
 *
 */

/* FreeRTOS includes. */
#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"

/* IO library includes. */
#include "FreeRTOS_IO.h"
#include "IOUtils_Common.h"
#include "FreeRTOS_uart.h"

#include "BS_Drivers.h"
#include "xil_exception.h"
#include "xintc.h"

xQueueHandle xQueue_uartReceive;


void Interrtup_Config(u32 INTC_BASEADDR, u32 INTC_Device_ID, u32 INTC_Deivce_MASKs);
void DeviceDriverHandler(void *CallbackRef);

portBASE_TYPE FreeRTOS_UART_open( Peripheral_Control_t * const pxPeripheralControl )
{

	pxPeripheralControl->write = FreeRTOS_UART_write;
	pxPeripheralControl->read = FreeRTOS_UART_read;
	pxPeripheralControl->ioctl = FreeRTOS_UART_ioctl;

	pxPeripheralControl->xBusSemaphore = xSemaphoreCreateMutex();
	pxPeripheralControl->xBlockTime = (50 / portTICK_RATE_MS );


	//	For receiving
	xQueue_uartReceive = xQueueCreate( 100, sizeof( u32 ) );

	if( xQueue_uartReceive == NULL )
	{
		return pdFAIL;
	}

	/*	Interrupt Configure	*/
	Interrtup_Config( XPAR_INTC_0_BASEADDR,
					XPAR_BS_MB_0_0_AXI_INTC_0_BS_MB_0_0_AXI_BLUETILE_BRIDGE_1_IRQ_INTR,
					XPAR_BS_MB_0_0_AXI_BLUETILE_BRIDGE_1_IRQ_MASK|XPAR_BS_MB_0_0_AXI_TIMER_0_INTERRUPT_MASK);


	return pdPASS;
}
/*-----------------------------------------------------------*/

size_t FreeRTOS_UART_write( Peripheral_Descriptor_t const pxPeripheral, const void *pvBuffer, const size_t xBytes )
{
	Peripheral_Control_t * const pxPeripheralControl = ( Peripheral_Control_t * const ) pxPeripheral;

	// Get the semaphore
	while ( xSemaphoreTake(pxPeripheralControl->xBusSemaphore, ( TickType_t ) 10 ) != pdTRUE )
	{

	}


	BS_printf((char*) pvBuffer);

	// Release the semaphore
	xSemaphoreGive( pxPeripheralControl->xBusSemaphore );

	return pdPASS;
}

size_t FreeRTOS_UART_read( Peripheral_Descriptor_t const pxPeripheral, void * const pvBuffer, const size_t xBytes )
{

	u32 *pChar = pvBuffer;
	u32 counter_receive = 0;


	while ( uxQueueMessagesWaiting( xQueue_uartReceive ) != 0)
	{
		pChar = pChar + 1;
		xQueueReceive(xQueue_uartReceive, pChar, 0);
		// 	printhex2(*pChar, 8);
		counter_receive = counter_receive + 1;
	}
	pChar = pChar - counter_receive;
	*pChar = counter_receive;


	// Do not have this function now
	return pdPASS;
}

portBASE_TYPE FreeRTOS_UART_ioctl( Peripheral_Descriptor_t pxPeripheral, uint32_t ulRequest, void *pvValue )
{


	// Do not have this function now
	return pdPASS;
}


void Interrtup_Config(u32 INTC_BASEADDR, u32 INTC_Device_ID, u32 INTC_Deivce_MASKs)
{
	Xil_ExceptionInit();

	XIntc_RegisterHandler(INTC_BASEADDR,
			INTC_Device_ID,
			(XInterruptHandler)DeviceDriverHandler,
			(void*) 0);

	XIntc_MasterEnable(INTC_BASEADDR);

	XIntc_SetIntrSvcOption(INTC_BASEADDR, XIN_SVC_ALL_ISRS_OPTION);

	XIntc_EnableIntr(INTC_BASEADDR, INTC_Deivce_MASKs);

	Xil_ExceptionRegisterHandler(XIL_EXCEPTION_ID_INT,
				(Xil_ExceptionHandler)XIntc_DeviceInterruptHandler,
				(void*) 0);

	Xil_ExceptionEnable();

}

void DeviceDriverHandler(void *CallbackRef)
{
	// BS_printf("interrupt \r\n");

	while ((Xil_In32(BaseAdd_BlueTile_irq + 0x00000004)) != 0)
	{
		u32 mesg, len_mesg, i;
		mesg = bt_rx_irq();
		len_mesg = mesg & 0x0000000F;

		mesg = bt_rx_irq();
		if (((mesg >> 16) & 0x0000FFFF) == 0x00000000)	// Messages from UART
		{
			for ( i = 0; i < len_mesg - 1; i ++)	// Receive payload
			{
				mesg = bt_rx_irq();
				xQueueSendToBackFromISR(xQueue_uartReceive, &mesg, 0);
			}
		}
	}

}


