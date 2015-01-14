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
#include <linux/i2c-dev-user.h>

#define SWI_IOCTL_MAGIC_NUM 'I'
#define SWI_IOCTL_I2C_ADDR_CONFIG _IOW(SWI_IOCTL_MAGIC_NUM,0x1,int)
#define SWI_IOCTL_I2C_FREQ_CONFIG _IOW(SWI_IOCTL_MAGIC_NUM,0x2,int)
#define ARRAY_SIZE(a) (sizeof(a) / sizeof((a)[0]))

static void pabort(const char *s)
{
	perror(s);
	abort();
}

static const char *device = "/dev/sierra_i2c";
static uint8_t bits = 8;
static uint16_t addr = 0;
static uint16_t reg = 0;
static uint16_t freq = 0;

static void transfer(int fd)
{
	int ret;
	uint8_t tx[] = {
		0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF,
		0x40, 0x00, 0x00, 0x00, 0x00, 0x95,
		0xDE, 0xAD, 0xBE, 0xEF, 0xBA, 0xAD,
		0xF0, 0x0D,
	};
	uint8_t rx[ARRAY_SIZE(tx)] = {0, };
	struct i2c_msg msg[] = {
		{
			.flags = 0,
			.len = ARRAY_SIZE(tx),
			.buf = (__u8 *)tx,
		},
		{
			.flags = I2C_M_RD,
			.len = ARRAY_SIZE(rx),
			.buf = (__u8 *)rx,
		},
	};
	struct i2c_rdwr_ioctl_data iodata = {
		.msgs = msg,
		.nmsgs = 2,
	};

	msg[0].addr = addr;
	msg[1].addr = addr;

	ret = ioctl(fd, I2C_RDWR, &iodata);
	if (ret < 1)
		pabort("can't send i2c message");

	for (ret = 0; ret < ARRAY_SIZE(tx); ret++) {
		if (!(ret % 6))
			puts("");
		printf("%.2X ", rx[ret]);
	}
	puts("");
}

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

	if (ioctl(fd, SWI_IOCTL_I2C_ADDR_CONFIG, addr) < 0) {
		printf("Failed to acquire bus access and/or talk to slave.\n");
		/* ERROR HANDLING; you can check errno to see what went wrong */
		exit(1);
	}


	if (ioctl(fd, SWI_IOCTL_I2C_FREQ_CONFIG, freq) < 0) {
		printf("Failed to acquire bus access and/or talk to slave.\n");
		/* ERROR HANDLING; you can check errno to see what went wrong */
		exit(1);
	}


	// transfer(fd);

	close(fd);

	return ret;
}
