#include "BS_rtc.h"
#include "Config.h"
#include "xstatus.h"





void rtc_reset()
{
	Xil_Out32(BaseAdd_rtc, 0x2A2B2C2D);
}




u32 rtc_read()
{
	u32 time;
	time =Xil_In32(BaseAdd_rtc + 0x04);

	return time;
}
