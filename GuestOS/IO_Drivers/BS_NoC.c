#include "BS_NoC.h"
#include "Config.h"
#include "xstatus.h"





void bt_tx(u32 mesg)
{
	Xil_Out32(BaseAdd_BlueTile + 0x0000000C, mesg);
}

u32 bt_rx()
{
	u32 message;

	while (!(Xil_In32(BaseAdd_BlueTile + 0x00000004)))
	{

	}

	message = Xil_In32(BaseAdd_BlueTile);



	Xil_Out32((BaseAdd_BlueTile + 0x00000008), 0x01);	//	Dequeue

	return message;
}


