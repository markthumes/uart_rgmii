#include <stdio.h>
#include <string.h>

int main(){
	const char* message = "Hello World. RGMII to UART Test. The quick brown fox jumped over the lazy dog.";
	for( int i = 0; i < strlen(message); i++ ){
		fprintf(stdout, "%02x\n", message[i]);
	}
	fprintf(stdout, "00\n");
}
