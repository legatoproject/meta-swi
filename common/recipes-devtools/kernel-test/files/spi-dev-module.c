/* Copyright (c) 2013, Wind River System. All rights reserved.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 and
 * only version 2 as published by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 */

#include <linux/module.h>
#include <linux/spi/spi.h>
static int bus_num;
static int cs;
struct spi_device *spi;

static struct spi_board_info spi_board_info[] __initdata = {
	{
		.modalias		= "spidev",
		.max_speed_hz		= 500000,
		.bus_num		= 0,
		.chip_select		= 1,
		.mode			= SPI_MODE_3 /*| SPI_LSB_FIRST*/,
	}
};

static int get_spi_device(struct device *dev, void *null)
{
	struct spi_device * exist_spi = to_spi_device(dev);
	if (exist_spi->chip_select == cs)
		spi_unregister_device(exist_spi);
}

static int __init spi_dev_init(void)
{
	struct spi_master *master = spi_busnum_to_master(bus_num);
	int dummy;

	if (master == NULL) {
		printk(" the spi bus %d doesn't exist!!", bus_num);
		return;
	}
	dummy	= device_for_each_child(&master->dev, NULL, get_spi_device);
	spi_board_info[0].bus_num = bus_num;
	spi_board_info[0].chip_select = cs;
	spi = spi_new_device(master, spi_board_info);
	if (!spi) {
		printk("fail to create spi device!!!\n");
		return -1;
	}

	return 0;
}
module_init(spi_dev_init);

static void __exit spi_dev_exit(void)
{
	spi_unregister_device(spi);
}
module_exit(spi_dev_exit);

MODULE_ALIAS("spe dev");
module_param(bus_num, int, 0644);
MODULE_PARM_DESC(bus_num, "the spi bus number");
module_param(cs, int, 0644);
MODULE_PARM_DESC(cs, "chip select");
MODULE_LICENSE("GPL v2");
