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
#include <linux/platform_device.h>
#include <linux/pm_runtime.h>
#include <linux/gpio.h>
#include <linux/interrupt.h>
#include <linux/irqreturn.h>

#include <mach/hardware.h>
//#include <mach/irqs.h>

#ifdef CONFIG_ARCH_YKEM
#include <mach/cpu_it_ctrl.const.h>

static int gpio_num = 94;
static int gpio_peer_num = 95;
static int gpio_nnirq = 0;
#else 
static int gpio_num = 26;
#endif

static int irq_trigger = 1;

struct gpio_context {
	int nr_gpio;
	int nr_irq;
	bool nr_irq_state;
};

static irqreturn_t gpio_test_handler(int irq, void *data)
{
#ifdef CONFIG_ARCH_YKEM
	extern int ykem_gpio_set_dataout( int gpio, int value );
	if( irq_trigger & 0x0C )
		ykem_gpio_set_dataout( gpio_peer_num, irq_trigger & 0x8 ? 1 : 0 );

	gpio_nnirq++;
	printk("irq=%d: %s, irq_trigger=%d gpio=%d nnirq=%d\n", irq, __func__, irq_trigger, gpio_num, gpio_nnirq);
#else
	printk("%s\n", __func__);
#endif	
	return IRQ_HANDLED;
}

static int gpio_test_install_nr_gpio(struct platform_device *pdev)
{
	int nr_irq;
	int ret;

	dev_dbg(&pdev->dev, "gpio_test_install_nr_gpio\n");

#ifdef CONFIG_ARCH_YKEM
	*(volatile u32 *)(IO_ADDRESS(0x70290328)) = gpio_num;
	nr_irq = CPU_IT_CTRL_IT_ID_GPIO_INTR02;
#else
	nr_irq = MSM_GPIO_TO_INT(gpio_num);
#endif
	printk("gpio test irq number: %d\n", nr_irq);
	if (nr_irq < 0) {
		dev_err(&pdev->dev, "could not register gpio_test GPIO.\n");
		return -ENXIO;
	}

	if (irq_trigger != 1 && irq_trigger != 2 &&
		irq_trigger != 4 && irq_trigger != 8) {
		printk("%s: the vaild value for irq_trigger is 1, 2, 4, 8,\n"
			"reset it to 1", __func__);
		irq_trigger = 1;
	}

	dev_dbg(&pdev->dev, "gpio number  = %d and irq = %d\n",
			gpio_num, nr_irq);
	ret = request_irq(nr_irq, gpio_test_handler,
		irq_trigger, "gpio_test_irq", NULL);
	if (ret < 0) {
		dev_err(&pdev->dev, "could not register gpio_test IRQ %d.\n", ret);
		return ret;
	}

	return 0;
}

static int gpio_test_probe(struct platform_device *pdev)
{
	int ret;

	dev_dbg(&pdev->dev, "gpio_test_probe\n");

	ret = gpio_test_install_nr_gpio(pdev);
	if (ret < 0) {
		dev_err(&pdev->dev, "gpio irq install failed\n");
		return ret;
	}
	return 0;
}

int gpio_test_remove(struct platform_device *pdev)
{
#ifdef CONFIG_ARCH_YKEM
	free_irq(CPU_IT_CTRL_IT_ID_GPIO_INTR02, NULL);
#else
	free_irq(MSM_GPIO_TO_INT(gpio_num), NULL);
#endif
	return 0;
}

static struct platform_driver gpio_test_driver = {
	.probe = gpio_test_probe,
	.driver = { .name = "gpio_test", },
	.remove = gpio_test_remove,
};
MODULE_ALIAS("platform:gpio_test");

static	struct platform_device *pdev;
static int __init gpio_test_init(void)
{
	int err = -ENOMEM;
	pdev = platform_device_alloc("gpio_test", -1);
	if (!pdev)
		goto err_out;
	err = platform_device_add(pdev);
	if (err)
		goto err_out;
	return platform_driver_register(&gpio_test_driver);
err_out:
	printk("gpio_test platform device alloc failed!!\n");
	platform_device_put(pdev);
	return err;
}
module_init(gpio_test_init);

static void __exit gpio_test_exit(void)
{
	platform_driver_unregister(&gpio_test_driver);
	platform_device_unregister(pdev);
}
module_exit(gpio_test_exit);

module_param(gpio_num, int, 0644);
MODULE_PARM_DESC(gpio_num, "gpio number");
#ifdef CONFIG_ARCH_YKEM
module_param(gpio_peer_num, int, 0644);
MODULE_PARM_DESC(gpio_peer_num, "gpio peer number");
#endif
module_param(irq_trigger, int, 0644);
MODULE_PARM_DESC(irq_trigger, "irq trigger method. 1 - RISING, 2 - FALLING, 4 - HIGH, 8 -LOW");
MODULE_LICENSE("GPL v2");
