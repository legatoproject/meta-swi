/*
 * WM8944.h -- WM8944 Soc Audio driver
 *
 * Copyright 2015 Sierra Wireless
 *
 * Author: Jean Michel Chauvet <jchauvet@sierrawireless.com>,
 *         Gaetan Perrier <gperrier@sierrawireless.com>
 *
 * based on wm8940.h
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#ifndef _WM8944_H
#define _WM8944_H

/* sources for SYSCLK */
#define WM8944_SYSCLK_MCLK 1
#define WM8944_SYSCLK_FLL  2

struct wm8944_reg_mask_val {
	u16	reg;
	u16	mask;
	u16	val;
};

#endif /* _WM8944_H */
