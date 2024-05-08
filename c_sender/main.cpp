#include <stdio.h>
#include "udp.h"

uint8_t swapBytes(uint8_t byte){
	return ((0x0f & byte) << 4) | ((0xf0 & byte) >> 4);
}

uint8_t reverseBits(uint8_t bits){
	return 
		((0x01 & bits) << 7) |
		((0x02 & bits) << 5) |
		((0x04 & bits) << 3) |
		((0x08 & bits) << 1) |
		((0x10 & bits) >> 1) |
		((0x20 & bits) >> 3) |
		((0x40 & bits) >> 5) |
		((0x80 & bits) >> 7) ;
}

int main(){
	UDP udp;
	char msg[15];
	sprintf(msg, "Hello");
	for( int i = 0; i < 5; i++ )
		msg[5+i] = reverseBits(msg[i]);
	for( int i = 0; i < 5; i++ )
		msg[10+i] = swapBytes(msg[i]);
	udp.send("192.168.1.255", 80, msg, 15);

}
