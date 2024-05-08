#include <stdio.h>
#include <inttypes.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include <termios.h>

#define SERIAL_PORT "/dev/ttyUSB0"

int main() {
	int serial_port;
	struct termios tty;

	// Open the serial port
	serial_port = open(SERIAL_PORT, O_RDWR);
	if (serial_port < 0) {
		perror("Error opening serial port");
		return 1;
	}

	// Get current serial port settings
	if (tcgetattr(serial_port, &tty) != 0) {
		perror("Error getting serial port settings");
		return 1;
	}

	// Set baud rate
	cfsetospeed(&tty, B115200);
	cfsetispeed(&tty, B115200);

	// Set other serial port settings
	tty.c_cflag &= ~PARENB;         // Disable parity
	tty.c_cflag &= ~CSTOPB;         // One stop bit
	tty.c_cflag &= ~CSIZE;          // Clear data size bits
	tty.c_cflag |= CS8;             // 8 bits per byte
	tty.c_cflag &= ~CRTSCTS;        // Disable hardware flow control
	tty.c_cflag |= CREAD | CLOCAL;  // Enable receiver, ignore modem control lines

	// Set input mode
	tty.c_iflag &= ~(IGNBRK | BRKINT | ICRNL | INLCR | PARMRK | INPCK | ISTRIP | IXON);
	tty.c_iflag &= ~(IXON | IXOFF | IXANY); // Disable software flow control

	// Set output mode
	tty.c_oflag &= ~OPOST;  // Raw output

	// Set control mode
	tty.c_lflag &= ~(ECHO | ECHONL | ICANON | IEXTEN | ISIG);

	// Set timeout settings
	tty.c_cc[VMIN] = 1;  // Minimum number of characters to read
	tty.c_cc[VTIME] = 5; // Timeout in tenths of a second

	// Apply settings to serial port
	if (tcsetattr(serial_port, TCSANOW, &tty) != 0) {
		perror("Error setting serial port settings");
		return 1;
	}

	// Read from serial port
	while (1) {
		uint8_t buf[256];
		memset(buf,0,256);
		int bytes_read = read(serial_port, &buf, sizeof(buf));
		if (bytes_read < 0) {
			perror("Error reading from serial port");
			break;
		}
		if (bytes_read > 0) {
			buf[bytes_read] = '\0'; // Null-terminate the string
			printf("Received %d bytes: \"%12s\"", bytes_read, buf);
		}
		for( int i = 0; i < bytes_read; i++ ){
			fprintf(stdout, "%02x ", buf[i]);
		}
		fprintf(stdout, " | ");
		for( int i = 0; i < bytes_read; i++ ){
			fprintf(stdout, "%c ", (char)buf[i]);
		}
		fprintf(stdout, "\n");
	}

	// Close serial port
	close(serial_port);

	return 0;
}

