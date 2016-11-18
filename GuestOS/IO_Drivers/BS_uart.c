#include "BS_uart.h"



void BS_uart_virtualization_on()
{

	#if	(if_UART_on_BG == 0)
	{
		u32 header_0;
		u32 header_1;

		header_0 = (UART_X << 24) | (UART_Y << 16) | 0x01;
		header_1 = (CPU_X << 24) | (CPU_Y << 16) | 0x0000FFFF;

		bt_tx(header_0);
		bt_tx(header_1);
	}

	#else
	{
		u32 header_0;
		u32 header_1;
		u32 header_2;
		u32 header_3;

		header_0 = (BlueGrass_X << 24) | (BlueGrass_Y << 16) | 0x03;
		header_1 = (CPU_X << 24) | (CPU_Y << 16) | 0x0000FFFF;
		header_2 = (UART_X << 24) | (UART_Y << 16) | 0x01;
		header_3 = (CPU_X << 24) | (CPU_Y << 16) | 0x0000FFFF;

		bt_tx(header_0);
		bt_tx(header_1);
		bt_tx(header_2);
		bt_tx(header_3);
	}
	#endif

}

void BS_printf(char *c)
{
	unsigned bytes = 0;
	unsigned words = 0;
	unsigned i;



	for (bytes = 0; c[bytes] != '\0'; bytes++) {}

	words = ((bytes + 3) / 4) + 1;

	#if (if_UART_on_BG == 0)
	{
		u32 header_0;
		u32 header_1;

		header_0 = (UART_X << 24) | (UART_Y << 16) | words;
		header_1 = (CPU_X << 24) | (CPU_Y << 16);

		bt_tx(header_0, InstancePtr);
		bt_tx(header_1, InstancePtr);

	}
	#else
	{
		u32 header_0;
		u32 header_1;
		u32 header_2;
		u32 header_3;

		header_0 = (BlueGrass_X << 24) | (BlueGrass_Y << 16) | (words + 2);
		header_1 = (CPU_X << 24) | (CPU_Y << 16);
		header_2 = (UART_X << 24) | (UART_Y << 16) | words;
		header_3 = (CPU_X << 24) | (CPU_Y << 16);

		bt_tx(header_0);
		bt_tx(header_1);
		bt_tx(header_2);
		bt_tx(header_3);
	}
	#endif

	for (i = 1; i < words; i++) {
		unsigned w;
		w = ((unsigned) ((unsigned char) c[3])) << 24;
		w |= ((unsigned) ((unsigned char) c[2])) << 16;
		w |= ((unsigned) ((unsigned char) c[1])) << 8;
		w |= ((unsigned) ((unsigned char) c[0]));
		c += 4;
		bt_tx(w);
	}
}


void printhex2(unsigned x, unsigned size)
{
    unsigned i;
    char bytes[9];

    if ((size == 0) || (size > 8)) size = 8;
    i = size;
    bytes[i] = '\0';
    while(i) {
        unsigned c = x & 0xf;
        x = x >> 4;
        if (c >= 10) {
            c += 'A' - 10;
        } else {
            c += '0';
        }
        i--;
        bytes[i] = c;
    }
    BS_printf(bytes);
}

void printdec(unsigned x)
{
    if (x == 0) {
    	BS_printf("0");
    } else {
        char bytes[16];
        unsigned i = 15;

        bytes[i] = '\0';
        while (x > 0) {
            unsigned div = x / 10;
            unsigned rem = x - (div * 10);
            i--;
            bytes[i] = '0' + (char) rem;
            x = div;
        }
        BS_printf(&bytes[i]);
    }
}
