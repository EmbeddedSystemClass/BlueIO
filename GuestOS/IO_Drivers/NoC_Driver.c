#include "NoC_Driver.h"



void NoC_init()
{
	XLlFifoConfig(&FifoBT, FIFO_DEV_BT);
}

int XLlFifoConfig(XLlFifo *InstancePtr, u16 DeviceId)
{
	XLlFifo_Config *Config;
	int Status = XST_SUCCESS;

	/* Initialize the Device Configuration Interface driver */
	Config = XLlFfio_LookupConfig(DeviceId);
	if (!Config) {
		xil_printf("No device found for %d\r\n", DeviceId);
		return XST_FAILURE;
	}

	/*
	 * This is where the virtual address would be used, this example
	 * uses physical address.
	 */
	Status = XLlFifo_CfgInitialize(InstancePtr, Config, Config->BaseAddress);
	if (Status != XST_SUCCESS) {
		xil_printf("Initialisation failed\n\r");
		return Status;
	}

	/* Check for the Reset value */
	Status = XLlFifo_Status(InstancePtr);
	XLlFifo_IntClear(InstancePtr,0xffffffff);	// Fifo clear
	Status = XLlFifo_Status(InstancePtr);
	if(Status != 0x0) {
		xil_printf("\n ERROR : Reset value of ISR0 : 0x%x\r\n"
				   "Expected : 0x0\n\r", XLlFifo_Status(InstancePtr));
		return XST_FAILURE;
	}

	return Status;
}

int XLlFifoSend(XLlFifo *InstancePtr, u32  *Data, u32 Words)
{
	int i;

	for( i= 0; i <Words; i ++)
	{
		XLlFifo_TxPutWord(InstancePtr, *(Data + i));
	}

	/* Start Transmission by writing transmission length into the TLR */
	XLlFifo_iTxSetLen(InstancePtr, Words * 4);

	/* Check for Transmission completion */
	while( !(XLlFifo_IsTxDone(InstancePtr)) ){

	}

	/* Transmission Complete */
	return XST_SUCCESS;
}


int XLlFifoReceive (XLlFifo *InstancePtr, u32* DestinationAddr)
{
	int i;
	u32 RxWord;
	u32 ReceiveLength;

	ReceiveLength = XLlFifo_iRxGetLen(InstancePtr);

	/* Start Receiving */
	for ( i=0; i < ReceiveLength/4; i++){
		RxWord = 0;
		RxWord = XLlFifo_RxGetWord(InstancePtr);
		*(DestinationAddr + i) = RxWord;
		xil_printf("%x\r\n", RxWord);
	}

	return XST_SUCCESS;
}

int if_mesg_coming (XLlFifo *InstancePtr)
{
	u32 if_mesg = 0;

	if_mesg = Xil_In32((InstancePtr->BaseAddress) + (0x0000001c));

	return if_mesg;
}


void bt_tx_mb(u32 mesg)
{
	u32 message[1];

	message[0] = mesg;

	XLlFifoSend(&FifoBT, message, 1);

}


