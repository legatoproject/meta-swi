/*
 * i2c testing utility (using i2c-ddev driver)
 *
 * Copyright (c) 2007  MontaVista Software, Inc.
 * Copyright (c) 2007  Anton Vorontsov <avorontsov@ru.mvista.com>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License.
 *
 * Cross-compile with cross-gcc -I/path/to/cross-kernel/include
 */

#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <linux/types.h>
#include <linux/i2c.h>
#include <linux/sierra_i2cdev.h>

#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

static void pabort(const char *s)
{
	perror(s);
	abort();
}

static const char *device = "/dev/sierra_i2c";
static uint8_t bits = 8;
int *addr = 0;
static uint16_t reg = 0;
static uint16_t freq = 0;

static void print_usage(const char *prog)

{
	printf("Usage: %s [-Dba]\n", prog);
	puts("  -D --device   device to use (default /dev/i2c-0)\n"
	     "  -b --bpw      bits per word \n"
	     "  -a --address    i2c client address\n"
	     "  -r --register    i2c client register\n"
	     "  -f --freq    i2c frequency \n");
	exit(1);
}

static void parse_opts(int argc, char *argv[])
{
	while (1) {
		static const struct option lopts[] = {
			{ "device",  1, 0, 'D' },
			{ "bpw",     1, 0, 'b' },
			{ "address", 1, 0, 'a' },
			{ "register", 1, 0, 'r' },
			{ "frequency", 1, 0, 'f' },
			{ NULL, 0, 0, 0 },
		};
		int c;

		c = getopt_long(argc, argv, "D:b:a:r:f:", lopts, NULL);

		if (c == -1)
			break;

		switch (c) {
		case 'D':
			device = optarg;
			break;
		case 'b':
			bits = atoi(optarg);
			break;
		case 'a':
			addr = atoi(optarg);
			break;
		case 'r':
			reg = atoi(optarg);
			break;
		case 'f':
			freq = atoi(optarg);
			break;
		default:
			print_usage(argv[0]);
			break;
		}
	}
}

int main(int argc, char *argv[])
{
	int ret = 0;
	int fd, res;

	parse_opts(argc, argv);

	fd = open(device, O_RDWR);
	if (fd < 0)
		pabort("can't open device");

	if (ioctl(fd, SWI_IOCTL_I2C_ADDR_CONFIG, &addr) < 0) {
		printf("Failed to acquire bus access and/or talk to slave.\n");
		/* ERROR HANDLING; you can check errno to see what went wrong */
		exit(1);
	}


	if (ioctl(fd, SWI_IOCTL_I2C_FREQ_CONFIG, &freq) < 0) {
		printf("Failed to acquire bus access and/or talk to slave.\n");
		/* ERROR HANDLING; you can check errno to see what went wrong */
		exit(1);
	}


	// transfer(fd);

	close(fd);

	return ret;
}
