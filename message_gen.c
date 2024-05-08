#include <stdio.h>
#include <string.h>

int main(){
	const char* msg = "Hello World";
	char buf[92];
	snprintf(buf, strlen(msg), msg);
	for( int i = 0; i < strlen(msg); i++ ){
		fprintf(stdout, "%02x\n", msg[i]);
	}
}
