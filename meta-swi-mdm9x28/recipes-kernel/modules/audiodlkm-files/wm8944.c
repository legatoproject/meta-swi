/*
 * WM8944.c  --  WM8944 ALSA Soc Audio driver
 *
 * Copyright  2015 Sierra Wireless
 *
 * Author: Jean Michel Chauvet <jchauvet@sierrawireless.com>
 *         Gaetan Perrier <gperrier@sierrawireless.com>
 *
 * Based on wm8940.c
 *     Author: Jonathan Cameron <jic23@cam.ac.uk>
 *
 *     Based on wm8510.c
 *         Copyright  2006 Wolfson Microelectronics PLC.
 *         Author:  Liam Girdwood <lrg@slimlogic.co.uk>
 *
 * and based on wm8994.c
 *     Copyright 2009 Wolfson Microelectronics plc
 *     Author: Mark Brown <broonie@opensource.wolfsonmicro.com>
 *
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 *
 * Not currently handled:
 * FLL
 * No use made of gpio
 * L/HPF, 3D Surround, notch filter, re-tune EQ, DRC
 * digital mic
 * Soft Start
 * jack detection
 * video buffer
 */
#include <linux/module.h>
#include <linux/moduleparam.h>
#include <linux/kernel.h>
#include <linux/init.h>
#include <linux/delay.h>
#include <linux/pm.h>
#include <linux/i2c.h>
#include <linux/platform_device.h>
#include <linux/pm_runtime.h>
#include <linux/spi/spi.h>
#include <linux/slab.h>
#include <sound/core.h>
#include <sound/pcm.h>
#include <sound/pcm_params.h>
#include <sound/soc.h>
#include <sound/initval.h>
#include <sound/tlv.h>
#include <linux/debugfs.h>

#include "wm8944.h"

#include <linux/mfd/wm8944/registers.h>
#include <linux/mfd/wm8944/pdata.h>
#include <linux/mfd/wm8944/core.h>

struct wm8944;

struct wm8944_priv {
	struct wm8944 *wm8944;
	struct snd_soc_codec *codec;
	unsigned int sysclk;
	unsigned int sysclk_src;
	void *control_data;
	struct wm8944_pdata *pdata;
	int vmid_refcount;
	enum wm8944_vmid_mode vmid_mode;
	int codec_initializing;
	struct work_struct work;
};


#ifdef CONFIG_DEBUG_FS
struct wm8944_priv *debug_wm8944_priv;
#endif


static const char *wm8944_companding[] = { "Off", "NC", "u-law", "A-law" };
static const struct soc_enum wm8944_adc_companding_enum
= SOC_ENUM_SINGLE(WM8944_COMPANDINGCTL, 1, 4, wm8944_companding);
static const struct soc_enum wm8944_dac_companding_enum
= SOC_ENUM_SINGLE(WM8944_COMPANDINGCTL, 3, 4, wm8944_companding);

static const char *wm8944_mic_bias_level_text[] = {"0.9", "0.65"};
static const struct soc_enum wm8944_mic_bias_level_enum
= SOC_ENUM_SINGLE(WM8944_INPUTCTL, 6, 2, wm8944_mic_bias_level_text);

static const char *wm8944_filter_mode_text[] = {"Audio", "Application"};
static const struct soc_enum wm8944_filter_mode_enum
= SOC_ENUM_SINGLE(WM8944_ADCCTL2, 6, 2, wm8944_filter_mode_text);

static const char *wm8944_dsp_mode_text[] = {"Record", "Playback", "General1", "General2"};
static const struct soc_enum wm8944_dsp_mode_enum
= SOC_ENUM_SINGLE(WM8944_SECFG, 0, 4, wm8944_dsp_mode_text);

static const char *wm8944_sys_clock_src_text[] = {"MCLK", "FLL"};
static const struct soc_enum wm8944_sys_clock_src_enum
= SOC_ENUM_SINGLE(WM8944_CLOCK, 8, 2, wm8944_sys_clock_src_text);

static const char *wm8944_audio_intf_format_text[] = {"Reserved",
	"Left Justified", "I2S", "DSP/PCM"};
static const struct soc_enum wm8944_audio_intf_format_enum
= SOC_ENUM_SINGLE(WM8944_IFACE, 0, 4, wm8944_audio_intf_format_text);

static const char *wm8944_audio_intf_word_length_text[] = {"16 bits", "20 bits",
       "24 bits", "32 bits"};
static const struct soc_enum wm8944_audio_intf_word_length_enum
= SOC_ENUM_SINGLE(WM8944_IFACE, 2, 4, wm8944_audio_intf_word_length_text);

static DECLARE_TLV_DB_SCALE(WM8944_spk_vol_tlv, -5700, 100, 0); //min = -57 dB , step = 1 dB, , mute = 0
static DECLARE_TLV_DB_SCALE(WM8944_inpga_vol_tlv, -1200, 75, 0);  //min = -12 dB , step = 0.75 dB, , mute = 0

static DECLARE_TLV_DB_SCALE(WM8944_drc_ng_min_tlv, -3600, 600, 0); //min = -36 dB , step = 6 dB, , mute = 0
static DECLARE_TLV_DB_SCALE(WM8944_drc_min_tlv, -3600, 600, 0); //min = -36 dB , step = 6 dB, , mute = 0
static DECLARE_TLV_DB_SCALE(WM8944_drc_max_tlv, 1200, 600, 0);   //min = 12 dB , step = 6 dB, , mute = 0

static DECLARE_TLV_DB_SCALE(WM8944_adc_tlv, -7200, 37, 1); //min = -72 dB, step = 0.375 dB, mute = 1


static const struct snd_kcontrol_new wm8944_snd_controls[] = {
	SOC_ENUM("DAC Companding", wm8944_dac_companding_enum),
	SOC_ENUM("ADC Companding", wm8944_adc_companding_enum),


	SOC_SINGLE("Clock Master Mode", WM8944_CLOCK, 0, 1, 0),
	SOC_SINGLE("Sys Clock Enable Switch", WM8944_CLOCK, 9, 1, 0),
	SOC_ENUM("Sys Clock Source", wm8944_sys_clock_src_enum),

	SOC_SINGLE("LDO Enable Switch", WM8944_LDO, 15, 1, 0),

	SOC_ENUM("Interface Format", wm8944_audio_intf_format_enum),
	SOC_ENUM("Interface Word Length", wm8944_audio_intf_word_length_enum),

	// DRC : Dynamic Range Compressor
	SOC_SINGLE("DRC Noise Gate Switch", WM8944_DRCCTL1, 8, 1, 0),
	SOC_SINGLE("DRC Switch", WM8944_DRCCTL1, 7, 1, 0),
	SOC_SINGLE("DRC Quick Release Switch", WM8944_DRCCTL1, 2, 1, 0),
	SOC_SINGLE("DRC Anti Clip Switch", WM8944_DRCCTL1, 8, 1, 0),
	SOC_SINGLE_TLV("DRC NG Min Gain", WM8944_DRCCTL2, 9, 12, 0,
		       WM8944_drc_ng_min_tlv),
	SOC_SINGLE_TLV("DRC Min Gain", WM8944_DRCCTL2, 2, 4, 0,
		       WM8944_drc_min_tlv),
	SOC_SINGLE_TLV("DRC Max Gain", WM8944_DRCCTL2, 0, 3, 1,
		       WM8944_drc_max_tlv),
	SOC_SINGLE("DRC Capture Decay", WM8944_DRCCTL3, 0, 8, 0),
	SOC_SINGLE("DRC Capture Attack", WM8944_DRCCTL3, 4, 11, 0),

	SOC_SINGLE("DRC KNEE2 In", WM8944_DRCCTL4, 8, 31, 0),
	SOC_SINGLE("DRC KNEE In", WM8944_DRCCTL4, 8, 60, 0),

	SOC_SINGLE("DRC KNEE2 Out Switch", WM8944_DRCCTL5, 13, 1, 0),
	SOC_SINGLE("DRC KNEE2 Out", WM8944_DRCCTL5, 3, 31, 0),
	SOC_SINGLE("DRC HI Comp", WM8944_DRCCTL5, 0, 5, 0),

	SOC_SINGLE("DRC QR Threshold", WM8944_DRCCTL6, 2, 3, 0),
	SOC_SINGLE("DRC QR Decay", WM8944_DRCCTL6, 0, 3, 0),

	SOC_SINGLE("DRC NG Slope", WM8944_DRCCTL7, 8, 3, 0),
	SOC_SINGLE("DRC Comp Slope", WM8944_DRCCTL7, 2, 4, 0),
	SOC_SINGLE("DRC Init value", WM8944_DRCCTL7, 0, 31, 0),

	// Input PGA
	SOC_SINGLE("Capture PGA Mute Switch", WM8944_INPUTPGAGAINCTL,
		   WM8944_INPGA_MUTE_SHIFT, 1, 1),
	SOC_SINGLE("Capture PGA ZC Switch", WM8944_INPUTPGAGAINCTL,
		   WM8944_INPGA_ZC_SHIFT, 1, 0),
	SOC_SINGLE_TLV("Capture PGA Volume", WM8944_INPUTPGAGAINCTL,
		       WM8944_INPGA_VOL_SHIFT, 63, 0, WM8944_inpga_vol_tlv),


	// Line Output Mixer Attenuation

	SOC_SINGLE_TLV("AUX/IN1 to Line Out Mixer Atten", WM8944_LINEMIXCTL2,
		       10, 1, 0, WM8944_adc_tlv),
	SOC_SINGLE_TLV("IN1 to Line Out Mixer Atten", WM8944_LINEMIXCTL2,9, 1,
		       0, WM8944_adc_tlv),
	SOC_SINGLE_TLV("InPGA to Line Out Mixer Atten", WM8944_LINEMIXCTL2,6, 1,
		       0, WM8944_adc_tlv),
	SOC_SINGLE_TLV("DAC to Line Out Mixer Atten", WM8944_LINEMIXCTL2,3, 1,
		       0, WM8944_adc_tlv),
	SOC_SINGLE_TLV("AUX to Line Out Mixer Atten", WM8944_LINEMIXCTL2,0, 1,
		       0, WM8944_adc_tlv),

	// Speaker output  Attenuation
	SOC_SINGLE("AUX to SPKOUTP Mixer Atten", WM8944_SPEAKMIXCTL3,
	           8, 1, 0),
	SOC_SINGLE("Speaker PGA to SPKOUTP Mixer Atten",
	           WM8944_SPEAKMIXCTL3, 7, 1, 0),
	SOC_SINGLE("IN1 to SPKOUTN Mixer Atten", WM8944_SPEAKMIXCTL4,
	           9, 1, 0),
	SOC_SINGLE("Speaker PGA to SPKOUTN Mixer Atten",
			WM8944_SPEAKMIXCTL4, 7, 1, 0),

	SOC_SINGLE("Digital Playback Mute Switch", WM8944_DACVOL,
		   WM8944_DAC_MUTE_SHIFT, 1, 1),

	SOC_SINGLE_TLV("Digital Playback Volume", WM8944_DACVOL,
		       WM8944_DAC_VOL_SHIFT, 255, 0, WM8944_adc_tlv),
	SOC_SINGLE_TLV("Left Digital Capture Volume", WM8944_LADCVOL, 0, 255, 0,
		       WM8944_adc_tlv),
	SOC_SINGLE_TLV("Right Digital Capture Volume", WM8944_RADCVOL, 0, 255,
		       0, WM8944_adc_tlv),

	SOC_ENUM("Mic Bias Level", wm8944_mic_bias_level_enum),

	SOC_SINGLE_TLV("Speaker Playback Volume", WM8944_SPEAKVOL,
		       WM8944_SPK_VOL_SHIFT, 63, 0, WM8944_spk_vol_tlv),
	SOC_SINGLE("Speaker Playback Mute Switch", WM8944_SPEAKVOL,
		   WM8944_SPK_PGA_MUTE_SHIFT, 1, 1),
	SOC_SINGLE("Speaker Playback ZC Switch", WM8944_SPEAKVOL,
		   WM8944_SPK_ZC_SHIFT, 1, 0),

	SOC_SINGLE("Input PGA Enable Switch", WM8944_POWER1,
		   WM8944_INPGA_ENA_SHIFT, 1, 0),
	SOC_SINGLE("Master Bias Enable Switch", WM8944_POWER1,
		   WM8944_BIAS_ENA_SHIFT, 1, 0),
	SOC_SINGLE("VMID Buffer Enable Switch", WM8944_POWER1,
		   WM8944_VMID_BUF_ENA_SHIFT, 1, 0),
	SOC_SINGLE("Left ADC Enable Switch", WM8944_POWER1,
		   WM8944_ADCL_ENA_SHIFT, 1, 0),

	SOC_SINGLE("SPKOUTP VDD Enable Switch", WM8944_POWER2,
		   WM8944_SPKP_SPKVDD_ENA_SHIFT, 1, 0),
	SOC_SINGLE("SPKOUTN VDD Enable Switch", WM8944_POWER2,
		   WM8944_SPKN_SPKVDD_ENA_SHIFT, 1, 0),
	SOC_SINGLE("SPKOUTP Mute Switch", WM8944_POWER2,
		   WM8944_SPKP_OP_MUTE_SHIFT, 1, 1),
	SOC_SINGLE("SPKOUTN Mute Switch", WM8944_POWER2,
		   WM8944_SPKN_OP_MUTE_SHIFT, 1, 1),
	SOC_SINGLE("SPKOUTP Enable Switch", WM8944_POWER2,
		   WM8944_SPKP_OP_ENA_SHIFT, 1, 0),
	SOC_SINGLE("SPKOUTN Enable Switch", WM8944_POWER2,
		   WM8944_SPKN_OP_ENA_SHIFT, 1, 0),
	SOC_SINGLE("Speaker PGA Mixer Mute Switch", WM8944_POWER2,
		   WM8944_SPK_MIX_MUTE_SHIFT, 1, 1),

	SOC_ENUM("DSP Configuration Mode", wm8944_dsp_mode_enum),

	SOC_ENUM("High Pass Filter Mode", wm8944_filter_mode_enum),
	SOC_SINGLE("High Pass Filter Switch", WM8944_ADCCTL2, 0, 1, 0),
	SOC_SINGLE("High Pass Filter Cut Off", WM8944_ADCCTL2, 1, 7, 0),
	SOC_SINGLE("Left ADC Inversion Switch", WM8944_ADCCTL1,
		   WM8944_ADCL_DAT_INV_SHIFT, 1, 0),
	SOC_SINGLE("Right ADC Inversion Switch", WM8944_ADCCTL1,
		   WM8944_ADCR_DAT_INV_SHIFT, 1, 0),
	SOC_SINGLE("ADC Mute All Switch", WM8944_ADCCTL1,
		   WM8944_ADC_MUTE_ALL_SHIFT, 1, 1),

	SOC_SINGLE("Left ADC Volume Update", WM8944_LADCVOL, 12, 1, 0),
	SOC_SINGLE("Left ADC Mute Switch", WM8944_LADCVOL, 8, 1, 1),
	SOC_SINGLE("Right ADC Volume Update", WM8944_RADCVOL, 12, 1, 0),
	SOC_SINGLE("Right ADC Mute Switch", WM8944_RADCVOL, 8, 1, 1),

	SOC_SINGLE("DAC Inversion Switch", WM8944_DACCTL1, 0, 1, 0),
	SOC_SINGLE("DAC Auto Mute Switch", WM8944_DACCTL1, 4, 1, 0),

	//
	SOC_SINGLE("ZC Timeout Clock Switch", WM8944_ADDCNTRL, 0, 1, 0),
	//
	SOC_SINGLE("BYP to Speak PGA Switch", WM8944_SPEAKMIXCTL1, 6, 1, 0),

#ifdef DEBUG_REGISTER_ACCESS
	//	SOC_SINGLE_EXT("reg00", SND_SOC_NOPM, 0, 65535, 0,  WM8944_get_reset,
	//		       WM8944_set_reset), /* R0  - Chip Revision Id1  */
	SOC_SINGLE("reg01", 0x01, 0, 65535, 0),  /* R1  - Chip Revision Id2 (RO) */
	SOC_SINGLE("reg02", 0x02, 0, 65535, 0),  /* R2  - Power 1 */
	SOC_SINGLE("reg03", 0x03, 0, 65535, 0),  /* R3  - Power 2 */
	SOC_SINGLE("reg04", 0x04, 0, 65535, 0),  /* R4  - Interface control */
	SOC_SINGLE("reg05", 0x05, 0, 65535, 0),  /* R5  - Companding Control */
	SOC_SINGLE("reg06", 0x06, 0, 65535, 0),  /* R6  - Clock control */
	SOC_SINGLE("reg07", 0x07, 0, 65535, 0),  /* R7  - Auto Increment Control */
	SOC_SINGLE("reg08", 0x08, 0, 65535, 0),  /* R8  - FLL control 1 */
	SOC_SINGLE("reg09", 0x09, 0, 65535, 0),  /* R9  - FLL control 2 */
	SOC_SINGLE("reg0A", 0x0A, 0, 65535, 0),  /* R10 - FLL control 3 */
	SOC_SINGLE("reg0B", 0x0B, 0, 65535, 0),  /* R11 - GPIO Config */
	SOC_SINGLE("reg0D", 0x0D, 0, 65535, 0),  /* R13 - GPIO1 Control */
	SOC_SINGLE("reg0E", 0x0E, 0, 65535, 0),  /* R14 - GPIO2 Control */
	SOC_SINGLE("reg10", 0x10, 0, 65535, 0),  /* R16 - System Interrupts (RO)*/
	SOC_SINGLE("reg11", 0x11, 0, 65535, 0),  /* R17 - Status Flags (RO)*/
	SOC_SINGLE("reg12", 0x12, 0, 65535, 0),  /* R18 - IRQ Config */
	SOC_SINGLE("reg13", 0x13, 0, 65535, 0),  /* R19 - System Interrupts Mask */
	SOC_SINGLE("reg14", 0x14, 0, 65535, 0),  /* R20 - Control Interface */
	SOC_SINGLE("reg15", 0x15, 0, 65535, 0),  /* R21 - DAC Control 1 */
	SOC_SINGLE("reg16", 0x16, 0, 65535, 0),  /* R22 - DAC Control 2 */
	SOC_SINGLE("reg17", 0x17, 0, 65535, 0),  /* R23 - DAC Volume (digital) */
	SOC_SINGLE("reg19", 0x19, 0, 65535, 0),  /* R25 - ADC Control 1 */
	SOC_SINGLE("reg1A", 0x1A, 0, 65535, 0),  /* R26 - ADC Control 2 */
	SOC_SINGLE("reg1B", 0x1B, 0, 65535, 0),  /* R27 - Left ADC Volume (digital) */
	SOC_SINGLE("reg1C", 0x1C, 0, 65535, 0),  /* R28 - Right ADC Volume (digital) */
	SOC_SINGLE("reg1D", 0x1D, 0, 65535, 0),  /* R29 - DRC Control 1 */
	SOC_SINGLE("reg1E", 0x1E, 0, 65535, 0),  /* R30 - DRC Control 2 */
	SOC_SINGLE("reg1F", 0x1F, 0, 65535, 0),  /* R31 - DRC Control 3 */
	SOC_SINGLE("reg20", 0x20, 0, 65535, 0),  /* R32 - DRC Control 4 */
	SOC_SINGLE("reg21", 0x21, 0, 65535, 0),  /* R33 - DRC Control 5 */
	SOC_SINGLE("reg22", 0x22, 0, 65535, 0),  /* R34 - DRC Control 6 */
	SOC_SINGLE("reg23", 0x23, 0, 65535, 0),  /* R35 - DRC Control 7 */
	SOC_SINGLE("reg24", 0x24, 0, 65535, 0),  /* R36 - DRC Status (RO) */
	SOC_SINGLE("reg25", 0x25, 0, 65535, 0),  /* R37 - Beep Control 1 */
	SOC_SINGLE("reg26", 0x26, 0, 65535, 0),  /* R38 - Video Buffer */
	SOC_SINGLE("reg27", 0x27, 0, 65535, 0),  /* R39 - Input Control */
	SOC_SINGLE("reg28", 0x28, 0, 65535, 0),  /* R40 - Input PGA Gain Control */
	SOC_SINGLE("reg2A", 0x2A, 0, 65535, 0),  /* R42 - Output Control */
	SOC_SINGLE("reg2B", 0x2B, 0, 65535, 0),  /* R43 - Speaker mixer Control 1 */
	SOC_SINGLE("reg2C", 0x2C, 0, 65535, 0),  /* R44 - Speaker mixer Control 2 */
	SOC_SINGLE("reg2D", 0x2D, 0, 65535, 0),  /* R45 - Speaker mixer Control 3 */
	SOC_SINGLE("reg2E", 0x2E, 0, 65535, 0),  /* R46 - Speaker mixer Control 4 */
	SOC_SINGLE("reg2F", 0x2F, 0, 65535, 0),  /* R47 - Speaker Volume Control */
	SOC_SINGLE("reg31", 0x31, 0, 65535, 0),  /* R49 - Liner mixer Control 1 */
	SOC_SINGLE("reg33", 0x33, 0, 65535, 0),  /* R51 - Liner L mixer Control 2 */
	SOC_SINGLE("reg35", 0x35, 0, 65535, 0),  /* R53 - LDO */
	SOC_SINGLE("reg36", 0x36, 0, 65535, 0),  /* R54 - BandGap */
	SOC_SINGLE("reg40", 0x40, 0, 65535, 0),  /* R64 - SE Config Selection */
	SOC_SINGLE("reg41", 0x41, 0, 65535, 0),  /* R65 - SE1_LHPF_CONFIG */
	SOC_SINGLE("reg42", 0x42, 0, 65535, 0),  /* R66 - SE1_LHPF_L */
	SOC_SINGLE("reg43", 0x43, 0, 65535, 0),  /* R67 - SE1_LHPF_R */
	SOC_SINGLE("reg44", 0x44, 0, 65535, 0),  /* R68 - SE1_3D_CONFIG */
	SOC_SINGLE("reg45", 0x45, 0, 65535, 0),  /* R69 - SE1_3D_L */
	SOC_SINGLE("reg46", 0x46, 0, 65535, 0),  /* R70 - SE1_3D_R */
	SOC_SINGLE("reg47", 0x47, 0, 65535, 0),  /* R71 - SE1_NOTCH_CONFIG */
	SOC_SINGLE("reg48", 0x48, 0, 65535, 0),  /* R72 - SE1_NOTCH_A10 */
	SOC_SINGLE("reg49", 0x49, 0, 65535, 0),  /* R73 - SE1_NOTCH_A11 */
	SOC_SINGLE("reg4A", 0x4A, 0, 65535, 0),  /* R74 - SE1_NOTCH_A20 */
	SOC_SINGLE("reg4B", 0x4B, 0, 65535, 0),  /* R75 - SE1_NOTCH_A21 */
	SOC_SINGLE("reg4C", 0x4C, 0, 65535, 0),  /* R76 - SE1_NOTCH_A30 */
	SOC_SINGLE("reg4D", 0x4D, 0, 65535, 0),  /* R77 - SE1_NOTCH_A31 */
	SOC_SINGLE("reg4E", 0x4E, 0, 65535, 0),  /* R78 - SE1_NOTCH_A40 */
	SOC_SINGLE("reg4F", 0x4F, 0, 65535, 0),  /* R79 - SE1_NOTCH_A41 */
	SOC_SINGLE("reg50", 0x50, 0, 65535, 0),  /* R80 - SE1_NOTCH_A50 */
	SOC_SINGLE("reg51", 0x51, 0, 65535, 0),  /* R81 - SE1_NOTCH_A51 */
	SOC_SINGLE("reg52", 0x52, 0, 65535, 0),  /* R82 - SE1_NOTCH_M10 */
	SOC_SINGLE("reg53", 0x53, 0, 65535, 0),  /* R83 - SE1_NOTCH_M11 */
	SOC_SINGLE("reg54", 0x54, 0, 65535, 0),  /* R84 - SE1_NOTCH_M20 */
	SOC_SINGLE("reg55", 0x55, 0, 65535, 0),  /* R85 - SE1_NOTCH_M21 */
	SOC_SINGLE("reg56", 0x56, 0, 65535, 0),  /* R86 - SE1_NOTCH_M30 */
	SOC_SINGLE("reg57", 0x57, 0, 65535, 0),  /* R87 - SE1_NOTCH_M31 */
	SOC_SINGLE("reg58", 0x58, 0, 65535, 0),  /* R88 - SE1_NOTCH_M40 */
	SOC_SINGLE("reg59", 0x59, 0, 65535, 0),  /* R89 - SE1_NOTCH_M41 */
	SOC_SINGLE("reg5A", 0x5A, 0, 65535, 0),  /* R90 - SE1_NOTCH_M50 */
	SOC_SINGLE("reg5B", 0x5B, 0, 65535, 0),  /* R91 - SE1_NOTCH_M51 */
	SOC_SINGLE("reg5C", 0x5C, 0, 65535, 0),  /* R92 - SE1_DF1_CONFIG */
	SOC_SINGLE("reg5D", 0x5D, 0, 65535, 0),  /* R93 - SE1_DF1_L0 */
	SOC_SINGLE("reg5E", 0x5E, 0, 65535, 0),  /* R94 - SE1_DF1_L1 */
	SOC_SINGLE("reg5F", 0x5F, 0, 65535, 0),  /* R95 - SE1_DF1_L2 */
	SOC_SINGLE("reg60", 0x60, 0, 65535, 0),  /* R96 - SE1_DF1_R0 */
	SOC_SINGLE("reg61", 0x61, 0, 65535, 0),  /* R97 - SE1_DF1_R1 */
	SOC_SINGLE("reg62", 0x62, 0, 65535, 0),  /* R98 - SE1_DF1_R2 */
	SOC_SINGLE("reg63", 0x63, 0, 65535, 0),  /* R99 - SE2_HPF_CONFIG */
	SOC_SINGLE("reg64", 0x64, 0, 65535, 0),  /* R100 - SE2_RETUNE_CONFIG */
	SOC_SINGLE("reg65", 0x65, 0, 65535, 0),  /* R101 - SE2_RETUNE_C0 */
	SOC_SINGLE("reg66", 0x66, 0, 65535, 0),  /* R102 - SE2_RETUNE_C1 */
	SOC_SINGLE("reg67", 0x67, 0, 65535, 0),  /* R103 - SE2_RETUNE_C2 */
	SOC_SINGLE("reg68", 0x68, 0, 65535, 0),  /* R104 - SE2_RETUNE_C3 */
	SOC_SINGLE("reg69", 0x69, 0, 65535, 0),  /* R105 - SE2_RETUNE_C4 */
	SOC_SINGLE("reg6A", 0x6A, 0, 65535, 0),  /* R106 - SE2_RETUNE_C5 */
	SOC_SINGLE("reg6B", 0x6B, 0, 65535, 0),  /* R107 - SE2_RETUNE_C6 */
	SOC_SINGLE("reg6C", 0x6C, 0, 65535, 0),  /* R108 - SE2_RETUNE_C7 */
	SOC_SINGLE("reg6D", 0x6D, 0, 65535, 0),  /* R109 - SE2_RETUNE_C8 */
	SOC_SINGLE("reg6E", 0x6E, 0, 65535, 0),  /* R110 - SE2_RETUNE_C9 */
	SOC_SINGLE("reg6F", 0x6F, 0, 65535, 0),  /* R111 - SE2_RETUNE_C10 */
	SOC_SINGLE("reg70", 0x70, 0, 65535, 0),  /* R112 - SE2_RETUNE_C11 */
	SOC_SINGLE("reg71", 0x71, 0, 65535, 0),  /* R113 - SE2_RETUNE_C12 */
	SOC_SINGLE("reg72", 0x72, 0, 65535, 0),  /* R114 - SE2_RETUNE_C13 */
	SOC_SINGLE("reg73", 0x73, 0, 65535, 0),  /* R115 - SE2_RETUNE_C14 */
	SOC_SINGLE("reg74", 0x74, 0, 65535, 0),  /* R116 - SE2_RETUNE_C15 */
	SOC_SINGLE("reg75", 0x75, 0, 65535, 0),  /* R117 - SE2_RETUNE_C16 */
	SOC_SINGLE("reg76", 0x76, 0, 65535, 0),  /* R118 - SE2_RETUNE_C17 */
	SOC_SINGLE("reg77", 0x77, 0, 65535, 0),  /* R119 - SE2_RETUNE_C18 */
	SOC_SINGLE("reg78", 0x78, 0, 65535, 0),  /* R120 - SE2_RETUNE_C19 */
	SOC_SINGLE("reg79", 0x79, 0, 65535, 0),  /* R121 - SE2_RETUNE_C20 */
	SOC_SINGLE("reg7A", 0x7A, 0, 65535, 0),  /* R122 - SE2_RETUNE_C21 */
	SOC_SINGLE("reg7B", 0x7B, 0, 65535, 0),  /* R123 - SE2_RETUNE_C22 */
	SOC_SINGLE("reg7C", 0x7C, 0, 65535, 0),  /* R124 - SE2_RETUNE_C23 */
	SOC_SINGLE("reg7D", 0x7D, 0, 65535, 0),  /* R125 - SE2_RETUNE_C24 */
	SOC_SINGLE("reg7E", 0x7E, 0, 65535, 0),  /* R126 - SE2_RETUNE_C25 */
	SOC_SINGLE("reg7F", 0x7F, 0, 65535, 0),  /* R127 - SE2_RETUNE_C26 */
	SOC_SINGLE("reg80", 0x80, 0, 65535, 0),  /* R128 - SE2_RETUNE_C27 */
	SOC_SINGLE("reg81", 0x81, 0, 65535, 0),  /* R129 - SE2_RETUNE_C28 */
	SOC_SINGLE("reg82", 0x82, 0, 65535, 0),  /* R130 - SE2_RETUNE_C29 */
	SOC_SINGLE("reg83", 0x83, 0, 65535, 0),  /* R131 - SE2_RETUNE_C30 */
	SOC_SINGLE("reg84", 0x84, 0, 65535, 0),  /* R132 - SE2_RETUNE_C31 */
	SOC_SINGLE("reg85", 0x85, 0, 65535, 0),  /* R133 - SE2_5BEQ_CONFIG */
	SOC_SINGLE("reg86", 0x86, 0, 65535, 0),  /* R134 - SE2_5BEQ_L10G */
	SOC_SINGLE("reg87", 0x87, 0, 65535, 0),  /* R135 - SE2_5BEQ_L32G */
	SOC_SINGLE("reg88", 0x88, 0, 65535, 0),  /* R136 - SE2_5BEQ_L4G */
	SOC_SINGLE("reg89", 0x89, 0, 65535, 0),  /* R137 - SE2_5BEQ_L0P */
	SOC_SINGLE("reg8A", 0x8A, 0, 65535, 0),  /* R138 - SE2_5BEQ_L0A */
	SOC_SINGLE("reg8B", 0x8B, 0, 65535, 0),  /* R139 - SE2_5BEQ_L0B */
	SOC_SINGLE("reg8C", 0x8C, 0, 65535, 0),  /* R140 - SE2_5BEQ_L1P */
	SOC_SINGLE("reg8D", 0x8D, 0, 65535, 0),  /* R141 - SE2_5BEQ_L1A */
	SOC_SINGLE("reg8E", 0x8E, 0, 65535, 0),  /* R142 - SE2_5BEQ_L1B */
	SOC_SINGLE("reg8F", 0x8F, 0, 65535, 0),  /* R143 - SE2_5BEQ_L1C */
	SOC_SINGLE("reg90", 0x90, 0, 65535, 0),  /* R144 - SE2_5BEQ_L2P */
	SOC_SINGLE("reg91", 0x91, 0, 65535, 0),  /* R145 - SE2_5BEQ_L2A */
	SOC_SINGLE("reg92", 0x92, 0, 65535, 0),  /* R146 - SE2_5BEQ_L2B */
	SOC_SINGLE("reg93", 0x93, 0, 65535, 0),  /* R147 - SE2_5BEQ_L2C */
	SOC_SINGLE("reg94", 0x94, 0, 65535, 0),  /* R148 - SE2_5BEQ_L3P */
	SOC_SINGLE("reg95", 0x95, 0, 65535, 0),  /* R149 - SE2_5BEQ_L3A */
	SOC_SINGLE("reg96", 0x96, 0, 65535, 0),  /* R150 - SE2_5BEQ_L3B */
	SOC_SINGLE("reg97", 0x97, 0, 65535, 0),  /* R151 - SE2_5BEQ_L3C */
	SOC_SINGLE("reg98", 0x98, 0, 65535, 0),  /* R152 - SE2_5BEQ_L4P */
	SOC_SINGLE("reg99", 0x99, 0, 65535, 0),  /* R153 - SE2_5BEQ_L4A */
	SOC_SINGLE("reg9A", 0x9A, 0, 65535, 0),  /* R154 - SE2_5BEQ_L4B */
	SOC_SINGLE("reg9B", 0x9B, 0, 65535, 0),  /* R155 - SE2_5BEQ_R10G */
	SOC_SINGLE("reg9C", 0x9C, 0, 65535, 0),  /* R156 - SE2_5BEQ_R32G */
	SOC_SINGLE("reg9D", 0x9D, 0, 65535, 0),  /* R157 - SE2_5BEQ_R4G */
	SOC_SINGLE("reg9E", 0x9E, 0, 65535, 0),  /* R158 - SE2_5BEQ_R0P */
	SOC_SINGLE("reg9F", 0x9F, 0, 65535, 0),  /* R159 - SE2_5BEQ_R0A */
	SOC_SINGLE("regA0", 0xA0, 0, 65535, 0),  /* R160 - SE2_5BEQ_R0B */
	SOC_SINGLE("regA1", 0xA1, 0, 65535, 0),  /* R161 - SE2_5BEQ_R1P */
	SOC_SINGLE("regA2", 0xA2, 0, 65535, 0),  /* R162 - SE2_5BEQ_R1A */
	SOC_SINGLE("regA3", 0xA3, 0, 65535, 0),  /* R163 - SE2_5BEQ_R1B */
	SOC_SINGLE("regA4", 0xA4, 0, 65535, 0),  /* R164 - SE2_5BEQ_R1C */
	SOC_SINGLE("regA5", 0xA5, 0, 65535, 0),  /* R165 - SE2_5BEQ_R2P */
	SOC_SINGLE("regA6", 0xA6, 0, 65535, 0),  /* R166 - SE2_5BEQ_R2A */
	SOC_SINGLE("regA7", 0xA7, 0, 65535, 0),  /* R167 - SE2_5BEQ_R2B */
	SOC_SINGLE("regA8", 0xA8, 0, 65535, 0),  /* R168 - SE2_5BEQ_R2C */
	SOC_SINGLE("regA9", 0xA9, 0, 65535, 0),  /* R169 - SE2_5BEQ_R3P */
	SOC_SINGLE("regAA", 0xAA, 0, 65535, 0),  /* R170 - SE2_5BEQ_R3A */
	SOC_SINGLE("regAB", 0xAB, 0, 65535, 0),  /* R171 - SE2_5BEQ_R3B */
	SOC_SINGLE("regAC", 0xAC, 0, 65535, 0),  /* R172 - SE2_5BEQ_R3C */
	SOC_SINGLE("regAD", 0xAD, 0, 65535, 0),  /* R173 - SE2_5BEQ_R4P */
	SOC_SINGLE("regAE", 0xAE, 0, 65535, 0),  /* R174 - SE2_5BEQ_R4A */
	SOC_SINGLE("regAF", 0xAF, 0, 65535, 0),  /* R175 - SE2_5BEQ_R4B */
#endif
};

#define WM8944_SPEAKVOL_MINUS_12_DB     0x2D  /* -12dB */

static int wm8944_unmute(struct snd_soc_codec *codec)
{
	u16 volume;
	struct wm8944_priv *wm8944 = snd_soc_codec_get_drvdata(codec);
	static bool is_first_call = true;
	static u16 orig_mute_dac_reg;
	static u16 orig_spk_vol;
	u16 mute_adcall_reg = snd_soc_read(codec, WM8944_ADCCTL1) &
		(~WM8944_ADC_MUTE_ALL_MASK);
	u16 mute_inpga_reg = snd_soc_read(codec, WM8944_INPUTPGAGAINCTL) &
		(~WM8944_INPGA_MUTE_MASK);

	if(is_first_call == true) {
		orig_mute_dac_reg = snd_soc_read(codec, WM8944_DACVOL) &
			(~WM8944_DAC_MUTE_MASK);
		orig_spk_vol = snd_soc_read(codec, WM8944_SPEAKVOL) &
			WM8944_SPK_VOL_MASK;
		is_first_call = false;
	}

	dev_dbg(codec->dev, " %s unmute +++ \n", __func__);

	/*  Set DAC mute  and  DAC volume 0 */
	snd_soc_write(codec, WM8944_DACVOL, WM8944_DAC_MUTE);
	snd_soc_update_bits(codec, WM8944_POWER2,
			    WM8944_SPK_MIX_MUTE_MASK,
			    0);

	/* Unmute Speak PGA and set volume as -57dB */
	snd_soc_update_bits(codec, WM8944_SPEAKVOL, WM8944_SPK_PGA_MUTE_MASK |
			    WM8944_SPK_VOL_MASK, 0);

	/* Unmute SPKP and SPKN */
	dev_dbg(codec->dev, " %s unmute spk_mix,spk vol,dac \n", __func__);
	snd_soc_update_bits(codec, WM8944_POWER2,
			    WM8944_SPKP_OP_MUTE_MASK|
			    WM8944_SPKN_OP_MUTE_MASK,
			    0);

	msleep(10);

	snd_soc_write(codec, WM8944_ADCCTL1, mute_adcall_reg);
	snd_soc_write(codec, WM8944_INPUTPGAGAINCTL, mute_inpga_reg);

	if(orig_spk_vol < WM8944_SPEAKVOL_MINUS_12_DB) {
		snd_soc_update_bits(codec, WM8944_SPEAKVOL, WM8944_SPK_VOL_MASK,
				    orig_spk_vol);
	}
	else {
		/* Increase speaker volume from -12dB, step 1 */
		for(volume = WM8944_SPEAKVOL_MINUS_12_DB;
		    volume <= orig_spk_vol; volume++) {
			snd_soc_update_bits(codec, WM8944_SPEAKVOL,
					    WM8944_SPK_VOL_MASK, volume);
		}
	}
	/* Unmute DAC, DAC volume set */
	snd_soc_write(codec, WM8944_DACVOL, orig_mute_dac_reg);
	wm8944->codec_initializing = 0;

	dev_dbg(codec->dev, " %s unmute --- \n", __func__);

	return 0;
}


static int wm8944_dac_event(struct snd_soc_dapm_widget *w,
                            struct snd_kcontrol *kcontrol, int event)
{
	struct snd_soc_codec *codec = w->dapm->component->codec;

	switch (event) {
	case SND_SOC_DAPM_PRE_PMU:
		dev_dbg(codec->dev, "%s SND_SOC_DAPM_PRE_PMU\n", __func__);
		wm8944_unmute(codec);
		break;

	case SND_SOC_DAPM_POST_PMU:
		dev_dbg(codec->dev, "%s SND_SOC_DAPM_POST_PMU\n", __func__);
		break;

	case SND_SOC_DAPM_PRE_PMD:
		dev_dbg(codec->dev, "%s SND_SOC_DAPM_PRE_PMD\n", __func__);
		break;

	case SND_SOC_DAPM_POST_PMD:
		dev_dbg(codec->dev, "%s SND_SOC_DAPM_POST_PMD\n", __func__);
		break;

	default:
		dev_dbg(codec->dev, "%s unknow event %d \n", __func__,event);
		break;
	}

	return 0;
}

static void vmid_prepare(struct snd_soc_codec *codec)
{
	struct wm8944_priv *wm8944 = snd_soc_codec_get_drvdata(codec);
	enum wm8944_vmid_mode vmid_mode = wm8944->vmid_mode;

	dev_dbg(codec->dev, "%s\n", __func__);

	if( wm8944->vmid_refcount == 0) {
		/* Enable speaker and Enable VMID to speaker */
		snd_soc_update_bits(codec, WM8944_OUTPUTCTL,
				    WM8944_SPKN_DISCH_MASK |
				    WM8944_SPKP_DISCH_MASK |
				    WM8944_LINE_DISCH_MASK |
				    WM8944_SPKP_VMID_OP_ENA_MASK|
				    WM8944_SPKN_VMID_OP_ENA_MASK|
				    WM8944_LINE_VMID_OP_ENA_MASK,
				    WM8944_SPKN_DISCH |
				    WM8944_SPKP_DISCH |
				    WM8944_LINE_DISCH |
				    WM8944_SPKP_VMID_OP_ENA|
				    WM8944_SPKN_VMID_OP_ENA|
				    WM8944_LINE_VMID_OP_ENA
				    );

		/* Eanble  VMID Fast Start and Start up Bias */
		snd_soc_update_bits(codec, WM8944_ADDCNTRL,
				    WM8944_VMID_FAST_START_MASK |
				    WM8944_STARTUP_BIAS_ENA_MASK |
				    WM8944_BIAS_SRC_MASK |
				    WM8944_VMID_RAMP_MASK,
				    WM8944_VMID_FAST_START  |
				    WM8944_STARTUP_BIAS_ENA |
				    WM8944_BIAS_SRC_STARTUP |
				    (vmid_mode << WM8944_VMID_RAMP_SHIFT));

		/*  LDO Start up Bias and enable LDO */
		snd_soc_update_bits(codec, WM8944_LDO,
				    WM8944_LDO_REF_SEL_FAST_MASK|
				    WM8944_LDO_BIAS_SRC_MASK|
				    WM8944_LDO_ENA_MASK,
				    WM8944_LDO_REF_SEL_FAST|
				    WM8944_LDO_BIAS_SRC|
				    WM8944_LDO_ENA);

		/* Set VMID_SEL for start up*/
		snd_soc_update_bits(codec, WM8944_POWER1,
				    WM8944_BIAS_ENA_MASK |
				    WM8944_VMID_BUF_ENA_MASK |
				    WM8944_VMID_SEL_MASK,
				    WM8944_BIAS_ENA |
				    WM8944_VMID_BUF_ENA |
				    WM8944_VMID_SEL_2x5K);

		/* Enable speaker output and PGA */
		snd_soc_update_bits(codec, WM8944_POWER2,
				    WM8944_SPK_MIX_ENA_MASK|
				    WM8944_DAC_ENA_MASK|
				    WM8944_SPKN_OP_ENA_MASK|
				    WM8944_SPKP_OP_ENA_MASK|
				    WM8944_SPK_PGA_ENA_MASK|
				    WM8944_OUT_ENA_MASK,
				    WM8944_SPK_MIX_ENA|
				    WM8944_DAC_ENA|
				    WM8944_SPKN_OP_ENA|
				    WM8944_SPKP_OP_ENA|
				    WM8944_SPK_PGA_ENA|
				    WM8944_OUT_ENA
				    );


		/* Enable power to speaker driver */
		snd_soc_update_bits(codec, WM8944_POWER2,
				    WM8944_SPKN_SPKVDD_ENA_MASK|
				    WM8944_SPKP_SPKVDD_ENA_MASK,
				    WM8944_SPKN_SPKVDD_ENA|
				    WM8944_SPKP_SPKVDD_ENA);

		msleep(10);

		/* Enable VMID */
		dev_dbg(codec->dev, "%s Enable VMID \n", __func__);
		snd_soc_update_bits(codec, WM8944_ADDCNTRL,
				    WM8944_VMID_ENA_MASK ,
				    WM8944_VMID_ENA);

	}
}

static void vmid_reference(struct snd_soc_codec *codec)
{
	struct wm8944_priv *wm8944 = snd_soc_codec_get_drvdata(codec);

	pm_runtime_get_sync(codec->dev);

	wm8944->vmid_refcount++;

	dev_dbg(codec->dev, "Referencing VMID, refcount is now %d\n",
		wm8944->vmid_refcount);

	if (wm8944->vmid_refcount == 1) {
		enum wm8944_vmid_mode vmid_mode = wm8944->vmid_mode;

		switch (vmid_mode) {
		default:
			WARN_ON(0 == "Invalid VMID mode");
		case WM8944_VMID_SLOW:
		case WM8944_VMID_NORMAL:
			msleep(100);
			break;

		case WM8944_VMID_FAST:
			msleep(50);
			break;
		}

		/* Set LDO and VMID for normal operation */
		snd_soc_update_bits(codec, WM8944_LDO,
				    WM8944_LDO_REF_SEL_FAST_MASK|
				    WM8944_LDO_BIAS_SRC_MASK,
				    0);

		snd_soc_update_bits(codec, WM8944_ADDCNTRL,
				    WM8944_VMID_FAST_START_MASK|
				    WM8944_STARTUP_BIAS_ENA_MASK,
				    0);

		snd_soc_update_bits(codec, WM8944_POWER1,
				    WM8944_VMID_SEL_MASK,
				    WM8944_VMID_SEL_2x50K);

	}
}

static void power_off_mute_seq(struct snd_soc_codec *codec)
{
	u16 spk_vol = snd_soc_read(codec, WM8944_SPEAKVOL) & WM8944_SPK_VOL_MASK;
	u16 mute_adcall_reg = snd_soc_read(codec, WM8944_ADCCTL1) &
		(~WM8944_ADC_MUTE_ALL_MASK);
	u16 mute_inpga_reg = snd_soc_read(codec, WM8944_INPUTPGAGAINCTL) &
		(~WM8944_INPGA_MUTE_MASK);
	u16 volume;

	dev_dbg(codec->dev, "%s mute +++ \n", __func__);

	mute_adcall_reg |= WM8944_ADC_MUTE_ALL;
	mute_inpga_reg |= WM8944_INPGA_MUTE;

	/* Decrease the volume to -12dB ,step 1 */
	if(spk_vol > WM8944_SPEAKVOL_MINUS_12_DB) {
		for(volume = spk_vol; volume >= WM8944_SPEAKVOL_MINUS_12_DB;
		    volume--) {
			snd_soc_update_bits(codec, WM8944_SPEAKVOL,
					    WM8944_SPK_VOL_MASK, volume);
		}
	}
	/* Set DAC mute and volume as 0 - mute */
	snd_soc_write(codec, WM8944_DACVOL, WM8944_DAC_MUTE);
	snd_soc_write(codec, WM8944_ADCCTL1, mute_adcall_reg);
	snd_soc_write(codec, WM8944_INPUTPGAGAINCTL, mute_inpga_reg);

	/* Mute spk_pga and set volume as -57dB */
	snd_soc_update_bits(codec, WM8944_SPEAKVOL, WM8944_SPK_PGA_MUTE_MASK |
			    WM8944_SPK_VOL_MASK,
			    WM8944_SPK_PGA_MUTE);

	dev_dbg(codec->dev, "%s mute  --- \n", __func__);
}

static void power_off_seq(struct snd_soc_codec *codec)
{

	struct wm8944_priv *wm8944 = snd_soc_codec_get_drvdata(codec);
	enum wm8944_vmid_mode vmid_mode = wm8944->vmid_mode;

	dev_dbg(codec->dev, "power_off_seq now +++ \n");

	power_off_mute_seq(codec);

	/* Select LDO for fast start up */
	snd_soc_update_bits(codec, WM8944_LDO,
		    WM8944_LDO_REF_SEL_FAST_MASK |
		    WM8944_LDO_BIAS_SRC_MASK,
		    WM8944_LDO_REF_SEL_FAST |
		    WM8944_LDO_BIAS_SRC_STARTUP);

	snd_soc_update_bits(codec, WM8944_POWER1,
		    WM8944_VMID_SEL_MASK,
		    WM8944_VMID_SEL_2x5K);

	/* Select VMID for fast start up */
	snd_soc_update_bits(codec, WM8944_ADDCNTRL,
		    WM8944_VMID_FAST_START_MASK |
		    WM8944_VMID_RAMP_MASK |
		    WM8944_BIAS_SRC_MASK,
		    WM8944_VMID_FAST_START |
		    (vmid_mode << WM8944_VMID_RAMP_SHIFT)|
		    WM8944_BIAS_SRC_STARTUP);

	/* Disable VMID */
	dev_dbg(codec->dev, "power_off_seq disable vmid \n");
	snd_soc_update_bits(codec, WM8944_ADDCNTRL,
		    WM8944_VMID_ENA_MASK ,
		    0);

	/* Discharge outputs */
	snd_soc_update_bits(codec, WM8944_OUTPUTCTL,
		    WM8944_SPKN_DISCH_MASK |
		    WM8944_SPKP_DISCH_MASK |
		    WM8944_LINE_DISCH_MASK,
		    WM8944_SPKN_DISCH |
		    WM8944_SPKP_DISCH |
		    WM8944_LINE_DISCH);

	/* Mute outputs */
	snd_soc_update_bits(codec, WM8944_POWER2,
		    WM8944_SPKN_OP_MUTE_MASK |
		    WM8944_SPKP_OP_MUTE_MASK,
		    WM8944_SPKN_OP_MUTE |
		    WM8944_SPKP_OP_MUTE);

	snd_soc_update_bits(codec, WM8944_OUTPUTCTL,
		    WM8944_LINE_MUTE_MASK,
		    WM8944_LINE_MUTE);

	/* Disable power to speaker driver */
	snd_soc_update_bits(codec, WM8944_POWER2,
		    WM8944_SPKP_SPKVDD_ENA_MASK|
		    WM8944_SPKN_SPKVDD_ENA_MASK,
		    0);

	/* Disable speaker outputs */
	snd_soc_update_bits(codec, WM8944_POWER2,
		    WM8944_SPKN_OP_ENA_MASK|
		    WM8944_SPKP_OP_ENA_MASK,
		    0);

	wm8944->codec_initializing =0;

	dev_dbg(codec->dev, "power_off_seq now --- \n");

}

static void wm8944_work(struct work_struct *work)
{
	struct wm8944_priv *priv = container_of(work, struct wm8944_priv,work);
	struct snd_soc_codec *codec = priv->codec;

	dev_dbg(codec->dev, " %s wm8944_work +++ \n", __func__);
	power_off_seq(codec);

}

static void vmid_dereference(struct snd_soc_codec *codec)
{
	struct wm8944_priv *wm8944 = snd_soc_codec_get_drvdata(codec);

	wm8944->vmid_refcount--;

	dev_dbg(codec->dev, "Dereferencing VMID, refcount is now %d\n",
		wm8944->vmid_refcount);

	if (wm8944->vmid_refcount == 0) {

	}

	pm_runtime_put(codec->dev);
}

static int vmid_event(struct snd_soc_dapm_widget *w,
		      struct snd_kcontrol *kcontrol, int event)
{
	struct snd_soc_codec *codec = w->dapm->component->codec;

	switch (event) {
	case SND_SOC_DAPM_POST_PMU:
		dev_dbg(codec->dev, "%s POST_PMU\n", __func__);
		vmid_reference(codec);
		break;

	case SND_SOC_DAPM_PRE_PMU:
		dev_dbg(codec->dev, "%s PRE_PMU\n", __func__);
		vmid_prepare(codec);
		break;

	case SND_SOC_DAPM_PRE_PMD:
		dev_dbg(codec->dev, "%s PRE_PMD\n", __func__);
		vmid_dereference(codec);
		break;
	}

	return 0;
}

static int spkoutn_vdd_event(struct snd_soc_dapm_widget *w,
		      struct snd_kcontrol *kcontrol, int event)
{
	struct snd_soc_codec *codec = w->dapm->component->codec;

	switch (event) {
	case SND_SOC_DAPM_PRE_PMU:
		dev_dbg(codec->dev, "%s PRE_PMU\n", __func__);
		break;

	case SND_SOC_DAPM_POST_PMD:
		dev_dbg(codec->dev, "%s POST_PMD\n", __func__);
		break;
	}

	return 0;
}

static int spkoutp_vdd_event(struct snd_soc_dapm_widget *w,
		      struct snd_kcontrol *kcontrol, int event)
{
	struct snd_soc_codec *codec = w->dapm->component->codec;

	switch (event) {
	case SND_SOC_DAPM_PRE_PMU:
		dev_dbg(codec->dev, "%s PRE_PMU\n", __func__);
		break;

	case SND_SOC_DAPM_POST_PMD:
		dev_dbg(codec->dev, "%s POST_PMD\n", __func__);
		break;
	}

	return 0;
}

static int configure_clock(struct snd_soc_codec *codec)
{
	struct wm8944_priv *wm8944 = snd_soc_codec_get_drvdata(codec);
	int new, ret;

	dev_dbg(codec->dev, "%s sysclk_src=%d\n", __func__, wm8944->sysclk_src);

	new = (wm8944->sysclk_src - 1) << WM8944_SYSCLK_SRC_SHIFT;
	ret = snd_soc_update_bits(codec, WM8944_CLOCK,
				     WM8944_SYSCLK_SRC_MASK, new);
	if (ret < 0)
		dev_err(codec->dev, "%s, Failed to update codec register %d\n",
			__func__, WM8944_CLOCK);

	return 0;
}

static int clk_sys_event(struct snd_soc_dapm_widget *w,
			 struct snd_kcontrol *kcontrol, int event)
{
	struct snd_soc_codec *codec = w->dapm->component->codec;

	switch (event) {
	case SND_SOC_DAPM_PRE_PMU:
		return configure_clock(codec);
	}

	return 0;
}

static const struct snd_kcontrol_new wm8944_speaker_mixer_controls[] = {
	// SOC_DAPM_SINGLE(xname, reg, shift, max, invert)
	SOC_DAPM_SINGLE("AUX diff to Speak PGA Switch",
			WM8944_SPEAKMIXCTL1, 10, 1, 0),
	SOC_DAPM_SINGLE("IN1 to Speak PGA Switch", WM8944_SPEAKMIXCTL1,
			9, 1, 0),
	SOC_DAPM_SINGLE("Input PGA to Speak PGA Switch", WM8944_SPEAKMIXCTL1,
			6, 1, 0),
	SOC_DAPM_SINGLE("Inv DAC to Speak PGA Switch", WM8944_SPEAKMIXCTL1,
			5, 1, 0),
	SOC_DAPM_SINGLE("DAC to Speak PGA Switch", WM8944_SPEAKMIXCTL1,3, 1, 0),
	SOC_DAPM_SINGLE("AUX to Speak PGA Switch", WM8944_SPEAKMIXCTL1, 0, 1, 0)
};

static const struct snd_kcontrol_new wm8944_lineout_mixer_controls[] = {
	// SOC_DAPM_SINGLE(xname, reg, shift, max, invert)
	SOC_DAPM_SINGLE("AUX diff to Line Out Switch", WM8944_LINEMIXCTL1,
			10, 1, 0),
	SOC_DAPM_SINGLE("IN1 to Line Out Switch", WM8944_LINEMIXCTL1, 9,
			1, 0),
	SOC_DAPM_SINGLE("Input PGA to Line Out Switch", WM8944_LINEMIXCTL1, 6,
			1, 0),
	SOC_DAPM_SINGLE("Inv DAC to Line Out Switch",
			WM8944_LINEMIXCTL1, 5, 1, 0),
	SOC_DAPM_SINGLE("DAC to Line Out Switch", WM8944_LINEMIXCTL1, 3,
			1, 0),
	SOC_DAPM_SINGLE("AUX to Line Out Switch", WM8944_LINEMIXCTL1, 0,
			1, 0),
};

static const struct snd_kcontrol_new wm8944_micpga_controls[] = {
	// SOC_DAPM_SINGLE(xname, reg, shift, max, invert)
	SOC_DAPM_SINGLE("AUX to Invert InPGA Switch", WM8944_INPUTCTL, 9, 1, 0),
	SOC_DAPM_SINGLE("IN1 to InPGA Switch", WM8944_INPUTCTL,
			0, 2, 0),
};

static const struct snd_kcontrol_new wm8944_spkoutn_mixer_controls[] = {
	// SOC_DAPM_SINGLE(xname, reg, shift, max, invert)
	SOC_DAPM_SINGLE("Speak PGA to Speaker N Switch", WM8944_SPEAKMIXCTL2,
			7, 1, 0),
	SOC_DAPM_SINGLE("IN1 to Speaker N Switch", WM8944_SPEAKMIXCTL2,
			9, 1, 0),
};

static const struct snd_kcontrol_new wm8944_spkoutp_mixer_controls[] = {
	// SOC_DAPM_SINGLE(xname, reg, shift, max, invert)
	SOC_DAPM_SINGLE("Speak PGA to Speaker P Switch", WM8944_SPEAKMIXCTL1,
			7, 1, 0),
	SOC_DAPM_SINGLE("AUX to Speaker P Switch", WM8944_SPEAKMIXCTL1,
			8, 1, 0),
};

static const struct snd_kcontrol_new wm8944_loopback_adc_dac_controls =
	SOC_DAPM_SINGLE("Switch", WM8944_COMPANDINGCTL,
			15, 1, 0);

static const struct snd_kcontrol_new wm8944_loopback_interface_controls =
	SOC_DAPM_SINGLE("Switch", WM8944_COMPANDINGCTL,
			5, 1, 0);

static const struct snd_soc_dapm_widget wm8944_dapm_widgets[] = {
	//SND_SOC_DAPM_MIXER(wname, wreg, wshift, winvert, wcontrols, wncontrols)
	SND_SOC_DAPM_MIXER("Speaker Mixer", WM8944_POWER2,
			   WM8944_SPK_MIX_ENA_SHIFT, 0,
			   &wm8944_speaker_mixer_controls[0],
			   ARRAY_SIZE(wm8944_speaker_mixer_controls)),
	SND_SOC_DAPM_MIXER("Line Mixer", SND_SOC_NOPM, 0, 0,
			   &wm8944_lineout_mixer_controls[0],
			   ARRAY_SIZE(wm8944_lineout_mixer_controls)),
	SND_SOC_DAPM_MIXER("Input PGA", WM8944_POWER1, WM8944_INPGA_ENA_SHIFT, 0,
			   &wm8944_micpga_controls[0],
			   ARRAY_SIZE(wm8944_micpga_controls)),
	SND_SOC_DAPM_MIXER("SPKOUTN Mixer", SND_SOC_NOPM, 0, 0,
			   &wm8944_spkoutn_mixer_controls[0],
			   ARRAY_SIZE(wm8944_spkoutn_mixer_controls)),
	SND_SOC_DAPM_MIXER("SPKOUTP Mixer", SND_SOC_NOPM, 0, 0,
			   &wm8944_spkoutp_mixer_controls[0],
			   ARRAY_SIZE(wm8944_spkoutp_mixer_controls)),

	SND_SOC_DAPM_SWITCH("ADC to DAC Loopback", SND_SOC_NOPM, 0, 0,
			    &wm8944_loopback_adc_dac_controls),
	SND_SOC_DAPM_SWITCH("Interface Loopback", SND_SOC_NOPM, 0, 0,
			    &wm8944_loopback_interface_controls),
	SND_SOC_DAPM_SUPPLY("SPKOUTN VDD", SND_SOC_NOPM,
			    0, 0, spkoutn_vdd_event,
			    SND_SOC_DAPM_PRE_PMU | SND_SOC_DAPM_POST_PMD),
	SND_SOC_DAPM_SUPPLY("SPKOUTP VDD", SND_SOC_NOPM,
			    0, 0, spkoutp_vdd_event,
			    SND_SOC_DAPM_PRE_PMU | SND_SOC_DAPM_POST_PMD),
	SND_SOC_DAPM_SUPPLY("VMID", WM8944_ADDCNTRL, SND_SOC_NOPM, 0,
			    vmid_event,
			    SND_SOC_DAPM_POST_PMU | SND_SOC_DAPM_PRE_PMU |
			    SND_SOC_DAPM_PRE_PMD),
	SND_SOC_DAPM_SUPPLY("SYS_CLK", WM8944_CLOCK,
			    WM8944_SYSCLK_ENA_SHIFT, 0, clk_sys_event,
			    SND_SOC_DAPM_PRE_PMU ),
	SND_SOC_DAPM_MICBIAS("Mic Bias", WM8944_POWER1, WM8944_MICB_ENA_SHIFT,
			     0),

	//SND_SOC_DAPM_DAC(wname, stname, wslot, wreg, wshift, winvert)
  SND_SOC_DAPM_DAC_E("DAC", "Audio Playback", WM8944_POWER2,
			 WM8944_DAC_ENA_SHIFT, 0,
			 wm8944_dac_event,
			 SND_SOC_DAPM_PRE_PMU| SND_SOC_DAPM_POST_PMU |
			 SND_SOC_DAPM_PRE_PMD| SND_SOC_DAPM_POST_PMD
			 ),

	SND_SOC_DAPM_ADC("ADC", "Left Capture", WM8944_POWER1,
			 WM8944_ADCL_ENA_SHIFT, 0),

	//SND_SOC_DAPM_PGA(wname, wreg, wshift, winvert, wcontrols, wncontrols)
	SND_SOC_DAPM_PGA("Speaker PGA", WM8944_POWER2,
			 WM8944_SPK_PGA_ENA_SHIFT, 0, NULL, 0),
	SND_SOC_DAPM_PGA("Line Out", WM8944_POWER2,
			 WM8944_OUT_ENA_SHIFT, 0, NULL, 0),

	SND_SOC_DAPM_OUTPUT("SPKOUTP"),
	SND_SOC_DAPM_OUTPUT("SPKOUTN"),
	SND_SOC_DAPM_OUTPUT("LINEOUT"),

	SND_SOC_DAPM_INPUT("AUX"),
	SND_SOC_DAPM_INPUT("IN1"),
};

/*
   DAPM audio route definition.
 *
 * Defines an audio route originating at source via control and finishing
 * at sink.
 */
/*
    snd_soc_dapm_route {
    const char *sink;
    const char *control;
    const char *source;
    };
    */
static const struct snd_soc_dapm_route audio_map[] = {

	/* Line output mixer */
	{"Line Mixer", "DAC to Line Out Switch", "DAC"},
	{"Line Mixer", "Inv DAC to Line Out Switch", "DAC"},
	{"Line Mixer", "AUX to Line Out Switch", "AUX"},
	{"Line Mixer", "IN1 to Line Out Switch", "IN1"},
	{"Line Mixer", "Input PGA to Line Out Switch", "Input PGA"},
	{"Line Mixer", "AUX diff to Line Out Switch", "IN1"},

	/* Speaker output mixer */
	{"Speaker Mixer", "DAC to Speak PGA Switch", "DAC"},
	{"Speaker Mixer", "Inv DAC to Speak PGA Switch", "DAC"},
	{"Speaker Mixer", "AUX to Speak PGA Switch", "AUX"},
	{"Speaker Mixer", "IN1 to Speak PGA Switch", "IN1"},
	{"Speaker Mixer", "Input PGA to Speak PGA Switch", "Input PGA"},
	{"Speaker Mixer", "AUX diff to Speak PGA Switch", "IN1"},
	{"Speaker Mixer", NULL, "VMID"},

	/* Speaker PGA */
	{"Speaker PGA", NULL, "Speaker Mixer"},

	/* SPKOUTN Mixer */
	{"SPKOUTN Mixer", "Speak PGA to Speaker N Switch", "Speaker PGA"},
	{"SPKOUTN Mixer", "IN1 to Speaker N Switch", "IN1"},

	/* SPKOUTP Mixer */
	{"SPKOUTP Mixer", "Speak PGA to Speaker P Switch", "Speaker PGA"},
	{"SPKOUTP Mixer", "AUX to Speaker P Switch", "AUX"},

	/* Outputs */
	{"SPKOUTN", NULL, "SPKOUTN Mixer"},
	{"SPKOUTP", NULL, "SPKOUTP Mixer"},
	{"LINEOUT", NULL, "Line Mixer"},

	{"ADC", NULL, "Input PGA"},

	/* Microphone PGA */
	{"Input PGA", "AUX to Invert InPGA Switch", "AUX"},
	{"Input PGA", "IN1 to InPGA Switch", "IN1"},

	/* loopback */
	{"ADC to DAC Loopback", "Switch", "ADC" },
	{"Interface Loopback", "Switch", "DAC" },
	{"DAC", NULL, "ADC to DAC Loopback"},
	{"ADC", NULL, "Interface Loopback"},

	/* Power */
	{"Mic Bias", NULL, "SYS_CLK"},
	{"DAC", NULL, "SYS_CLK"},
	{"ADC", NULL, "SYS_CLK"},
	{"SYS_CLK", NULL, "VMID"},
	{"SPKOUTP", NULL, "SPKOUTP VDD"},
	{"SPKOUTN", NULL, "SPKOUTN VDD"},
};

static int wm8944_add_widgets(struct snd_soc_codec *codec)
{
	struct snd_soc_dapm_context *dapm = &codec->component.dapm;
	int ret;

	dev_dbg(codec->dev, "%s\n", __func__);

	ret = snd_soc_dapm_new_controls(dapm, wm8944_dapm_widgets,
					ARRAY_SIZE(wm8944_dapm_widgets));
	if (ret)
		return ret;
	ret = snd_soc_dapm_add_routes(dapm, audio_map, ARRAY_SIZE(audio_map));
	if (ret)
		return ret;

	return ret;
}

static int wm8944_set_dai_fmt(struct snd_soc_dai *codec_dai, unsigned int fmt)
{
	struct snd_soc_codec *codec = codec_dai->codec;
	struct wm8944_priv *wm8944 = snd_soc_codec_get_drvdata(codec);

	u16 iface = snd_soc_read(codec, WM8944_IFACE) & 0xFFCC;
	u16 clk = snd_soc_read(codec, WM8944_CLOCK) & 0xFFFE;

	dev_dbg(codec->dev,"%s iface=0x%x clk=0x%x fmt=0x%x\n", __func__, iface,
	       clk, fmt);

	/* Indicated Codec path ,mix and power to be initialized */
	wm8944->codec_initializing = 1;

	switch (fmt & SND_SOC_DAIFMT_MASTER_MASK) {
	case SND_SOC_DAIFMT_CBM_CFM: // codec clk & FRM master
		clk |= 1;
		break;
	case SND_SOC_DAIFMT_CBS_CFS: // codec clk & FRM slav
		break;
	default:
		return -EINVAL;
	}

	snd_soc_write(codec, WM8944_CLOCK, clk);

	switch (fmt & SND_SOC_DAIFMT_FORMAT_MASK) {
	case SND_SOC_DAIFMT_I2S:
		iface |= 2;
		break;
	case SND_SOC_DAIFMT_LEFT_J:
		iface |= 1;
		break;
	case SND_SOC_DAIFMT_RIGHT_J://not supported
		break;
	case SND_SOC_DAIFMT_DSP_A:
	case SND_SOC_DAIFMT_DSP_B:
		iface |= 3;
		break;
	}

	switch (fmt & SND_SOC_DAIFMT_INV_MASK) {
	case SND_SOC_DAIFMT_NB_NF:
		break;
	case SND_SOC_DAIFMT_NB_IF:
		iface |= (1 << 4);
		break;
	case SND_SOC_DAIFMT_IB_NF:
		iface |= (1 << 4);
		break;
	case SND_SOC_DAIFMT_IB_IF:
		iface |= (1 << 5) | (1 << 4);
		break;
	}

	snd_soc_write(codec, WM8944_IFACE, iface);

	return 0;
}

static int wm8944_i2s_hw_params(struct snd_pcm_substream *substream,
				struct snd_pcm_hw_params *params,
				struct snd_soc_dai *dai)
{
	struct snd_soc_pcm_runtime *rtd = substream->private_data;
	struct snd_soc_codec *codec = rtd->codec;
	u16 iface = snd_soc_read(codec, WM8944_IFACE) & 0xFFF3;
	u16 addcntrl = snd_soc_read(codec, WM8944_ADDCNTRL) & 0x7FF0; /* erase the bit SYSCLK_RATE */
	u16 companding =  snd_soc_read(codec, WM8944_COMPANDINGCTL) & 0xFFDF;
	int ret;

	dev_dbg(codec->dev, "%s iface=0x%x addcntrl=0x%x companding=0x%x\n",
	       __func__, iface, addcntrl, companding);

	switch (params_rate(params)) {
	case 8000:
		addcntrl |= (0x3 << 0);
		break;
	case 11025:
		addcntrl |= (0x4 << 0);
		break;
	case 12000:
		addcntrl |= (0x5 << 0);
		break;
	case 16000:
		addcntrl |= (0x7 << 0);
		break;
	case 22050:
		addcntrl |= (0x8 << 0);
		break;
	case 24000:
		addcntrl |= (0x9 << 0);
		break;
	case 32000:
		addcntrl |= (0xB << 0);
		break;
	case 44100:
		addcntrl |= (0xC << 0);
		break;
	case 48000:
		addcntrl |= (0xD << 0);
		break;
	}
	ret = snd_soc_write(codec, WM8944_ADDCNTRL, addcntrl);
	if (ret)
		return ret;

	switch (params_format(params)) {
	case SNDRV_PCM_FORMAT_S8:
		companding |= ((1 << 3) | (1 << 1)); // ADC and DAC companding enabled
		break;
	case SNDRV_PCM_FORMAT_S16_LE:
		break;
	case SNDRV_PCM_FORMAT_S20_3LE:
		iface |= (1 << 2);
		break;
	case SNDRV_PCM_FORMAT_S24_LE:
		iface |= (2 << 2);
		break;
	case SNDRV_PCM_FORMAT_S32_LE:
		iface |= (3 << 2);
		break;
	}
	ret = snd_soc_write(codec, WM8944_COMPANDINGCTL, companding);
	if (ret)
		return ret;
	ret = snd_soc_write(codec, WM8944_IFACE, iface);

	return ret;
}

static int wm8944_mute(struct snd_soc_dai *dai, int mute)
{
	struct snd_soc_codec *codec = dai->codec;

	u16 mute_dac_reg = snd_soc_read(codec, WM8944_DACVOL) & (~WM8944_DAC_MUTE_MASK);
	u16 mute_adcall_reg = snd_soc_read(codec, WM8944_ADCCTL1) & (~WM8944_ADC_MUTE_ALL_MASK);
	u16 mute_inpga_reg = snd_soc_read(codec, WM8944_INPUTPGAGAINCTL) & (~WM8944_INPGA_MUTE_MASK);

	dev_dbg(dai->codec->dev, "%s mute=%d\n", __func__, mute);

	if (mute) {
		mute_dac_reg |= WM8944_DAC_MUTE;
		mute_adcall_reg |= WM8944_ADC_MUTE_ALL;
		mute_inpga_reg |= WM8944_INPGA_MUTE;
	}

	snd_soc_write(codec, WM8944_DACVOL, mute_dac_reg);
	snd_soc_write(codec, WM8944_ADCCTL1, mute_adcall_reg);
	snd_soc_write(codec, WM8944_INPUTPGAGAINCTL, mute_inpga_reg);

	return 0;

}


static int wm8944_trigger(struct snd_pcm_substream *substream, int cmd, struct snd_soc_dai *codec_dai)
{
	struct snd_soc_codec *codec = codec_dai->codec;
	struct wm8944_priv *wm8944 = snd_soc_codec_get_drvdata(codec);

	switch(cmd)
	{
	case SNDRV_PCM_TRIGGER_START:
	case SNDRV_PCM_TRIGGER_RESUME:
	case SNDRV_PCM_TRIGGER_PAUSE_RELEASE:
		if(substream->stream == SNDRV_PCM_STREAM_PLAYBACK)
		{
			/* PCM stream event,keep this code for debug in the future */
			dev_dbg(codec->dev," %s Playback cmd =%d ,stream %d ", __func__, cmd,substream->stream);
		}
		break;

	case SNDRV_PCM_TRIGGER_STOP:
	case SNDRV_PCM_TRIGGER_SUSPEND:
	case SNDRV_PCM_TRIGGER_PAUSE_PUSH:
		if(substream->stream == SNDRV_PCM_STREAM_PLAYBACK)
		{
			/* PCM stream event */
			dev_dbg(codec->dev," %s  PCM Stop cmd =%d ,stream %d ", __func__, cmd,substream->stream);
			wm8944->codec_initializing = 1;
			schedule_work(&wm8944->work);
		}
		break;
	}

	return 0;
}


static int wm8944_set_bias_level(struct snd_soc_codec *codec,
				 enum snd_soc_bias_level level)
{
	int ret = 0;

	dev_dbg(codec->dev, "%s level=%d\n", __func__, level);

	switch (level) {
	case SND_SOC_BIAS_ON:
		break;

	case SND_SOC_BIAS_PREPARE:
		break;

	case SND_SOC_BIAS_STANDBY:
		if (codec->component.dapm.bias_level == SND_SOC_BIAS_OFF) {
			snd_soc_update_bits(
				codec, WM8944_OUTPUTCTL,
				WM8944_SPKN_DISCH_MASK |
				WM8944_SPKP_DISCH_MASK |
				WM8944_LINE_DISCH_MASK |
				WM8944_SPKN_VMID_OP_ENA_MASK |
				WM8944_SPKP_VMID_OP_ENA_MASK |
				WM8944_LINE_VMID_OP_ENA_MASK,
				WM8944_SPKN_DISCH |
				WM8944_SPKP_DISCH |
				WM8944_LINE_DISCH |
				WM8944_SPKN_VMID_OP_ENA |
				WM8944_SPKP_VMID_OP_ENA |
				WM8944_LINE_VMID_OP_ENA);

			snd_soc_update_bits(codec, WM8944_POWER1,
					    WM8944_VMID_BUF_ENA_MASK |
					    WM8944_VMID_SEL_MASK,
					    WM8944_VMID_BUF_ENA |
					    WM8944_VMID_SEL_2x250K);
		}
		break;

	case SND_SOC_BIAS_OFF:
		snd_soc_update_bits(codec, WM8944_POWER1,
				    WM8944_VMID_BUF_ENA_MASK |
				    WM8944_BIAS_ENA_MASK |
				    WM8944_VMID_SEL_MASK,
				    0);
		break;
	}

	codec->component.dapm.bias_level = level;

	return ret;
}


static int wm8944_set_dai_sysclk(struct snd_soc_dai *codec_dai,
				 int clk_id, unsigned int freq, int dir)
{
	struct snd_soc_codec *codec = codec_dai->codec;
	struct wm8944_priv *wm8944 = snd_soc_codec_get_drvdata(codec);

	dev_dbg(codec->dev, "%s clk_id=%d freq=%d dir=%d, \n", __func__, clk_id,
	       freq, dir);

	switch (freq) {
	case 11289600:
	case 12000000:
	case 12288000:
	case 16934400:
	case 18432000:
	case 19200000:
		wm8944->sysclk = freq;
		wm8944->sysclk_src = clk_id;

		return 0;
	}
	return -EINVAL;
}

static int wm8944_set_dai_clkdiv(struct snd_soc_dai *codec_dai, int div_id,
				 int div)
{
	struct snd_soc_codec *codec = codec_dai->codec;
	u16 reg;
	int ret = 0;


	switch (div_id) {
	case WM8944_BCLKDIV:
		reg = snd_soc_read(codec, WM8944_CLOCK) & 0xFFF1;
		ret = snd_soc_write(codec, WM8944_CLOCK, reg | ((div&0x7)<<1));
		break;
	case WM8944_MCLKDIV:
		reg = snd_soc_read(codec, WM8944_CLOCK) & 0xFF1F;
		ret = snd_soc_write(codec, WM8944_CLOCK, reg | ((div&0x7)<<5));
		break;
	case WM8944_FLLCLKDIV:
		reg = snd_soc_read(codec, WM8944_FLLCTL1) & 0xE7FF;
		ret = snd_soc_write(codec, WM8944_FLLCTL1, reg |
				    ((div&0x3)<<11));
		break;
	case WM8944_FOCLKDIV:
		reg = snd_soc_read(codec, WM8944_FLLCTL1) & 0xF1FF;
		ret = snd_soc_write(codec, WM8944_FLLCTL1, reg |
				    ((div&0x7)<<8));
		break;
	}

	return ret;
}

#define WM8944_RATES SNDRV_PCM_RATE_8000_48000

#define WM8944_FORMATS (SNDRV_PCM_FMTBIT_S8 |  \
			SNDRV_PCM_FMTBIT_S16_LE |  \
			SNDRV_PCM_FMTBIT_S20_3LE | \
			SNDRV_PCM_FMTBIT_S24_LE |  \
			SNDRV_PCM_FMTBIT_S32_LE)

static struct snd_soc_dai_ops wm8944_dai_ops = {
	.hw_params    = wm8944_i2s_hw_params,
	.set_sysclk   = wm8944_set_dai_sysclk,
	.digital_mute = wm8944_mute,
	.set_fmt      = wm8944_set_dai_fmt,
	.set_clkdiv   = wm8944_set_dai_clkdiv,
	.trigger      = wm8944_trigger,
};

static struct snd_soc_dai_driver wm8944_dai = {
	.name = "wm8944-hifi",
	.id = 1,
	.playback = {
		.stream_name = "Playback",
		.channels_min = 1,
		.channels_max = 2,
		.rates = WM8944_RATES,
		.formats = WM8944_FORMATS,
	},
	.capture = {
		.stream_name = "Capture",
		.channels_min = 1,
		.channels_max = 2,
		.rates = WM8944_RATES,
		.formats = WM8944_FORMATS,
	},
	.ops = &wm8944_dai_ops,
	.symmetric_rates = 1,
};

#ifdef CONFIG_PM
static int wm8944_suspend(struct device *dev)
{
	dev_dbg(dev, "%s\n", __func__);

	return 0;
}

static int wm8944_resume(struct device *dev)
{
	dev_dbg(dev, "%s\n", __func__);
	return 0;
}
#endif


#ifdef CONFIG_PM
static int wm8944_codec_suspend(struct snd_soc_codec *codec)
{
	struct wm8944_priv *wm8944 = snd_soc_codec_get_drvdata(codec);

	dev_dbg(codec->dev, "%s\n", __func__);
	/* Sync reg_cache with the hardware */
	regcache_sync(wm8944->wm8944->regmap);

	return wm8944_set_bias_level(codec, SND_SOC_BIAS_OFF);
}

static int wm8944_codec_resume(struct snd_soc_codec *codec)
{
	dev_dbg(codec->dev, "%s\n", __func__);

	return wm8944_set_bias_level(codec, SND_SOC_BIAS_STANDBY);
}
#else
#define wm8944_codec_suspend NULL
#define wm8944_codec_resume NULL
#endif

static void wm8944_handle_pdata(struct wm8944_priv *wm8944)
{
	struct snd_soc_codec *codec = wm8944->codec;
	struct wm8944_pdata *pdata = wm8944->pdata;
	u16 reg;
	int ret;

	if (!pdata) {
		dev_dbg(codec->dev, "%s, No platform data supplied\n", __func__);
		return;
	}

	wm8944->vmid_mode = pdata->vmid_mode;

	ret = snd_soc_update_bits(codec, WM8944_OUTPUTCTL,
				  WM8944_SPK_VROI_MASK | WM8944_LINE_VROI_MASK,
				  (pdata->spk_vroi<<WM8944_SPK_VROI_SHIFT) |
				  (pdata->line_vroi<<WM8944_LINE_VROI_SHIFT));
	if (ret < 0)
		dev_err(codec->dev, "%s, Failed to update codec register %d\n",
			__func__, WM8944_OUTPUTCTL);

	reg = snd_soc_update_bits(codec, WM8944_INPUTCTL, WM8944_MICB_LVL_MASK,
				  pdata->micbias_lvl<<WM8944_MICB_LVL_SHIFT);
	if (ret < 0)
		dev_err(codec->dev, "%s, Failed to update codec register %d\n",
			__func__, WM8944_INPUTCTL);
}

static irqreturn_t wm8944_temp_warn(int irq, void *data)
{
	struct snd_soc_codec *codec = data;

	dev_err(codec->dev, "WM8944 Thermal warning\n");

	return IRQ_HANDLED;
}

static irqreturn_t wm8944_ldo_warn(int irq, void *data)
{
	struct snd_soc_codec *codec = data;

	dev_err(codec->dev, "WM8944 Under Voltage warning\n");

	return IRQ_HANDLED;
}

static int wm8944_codec_probe(struct snd_soc_codec *codec)
{
	struct wm8944_priv *wm8944 = snd_soc_codec_get_drvdata(codec);
	int ret = 0;

	wm8944->codec = codec;

	dev_dbg(codec->dev, "%s wm8944 0x%x\n", __func__, (u32)wm8944->wm8944);
	dev_dbg(codec->dev, "%s control_data 0x%x\n", __func__,
	       (u32)wm8944->control_data);
	dev_dbg(codec->dev, "%s pdata 0x%x\n", __func__, (u32)wm8944->pdata);

	if (ret < 0) {
		dev_err(codec->dev, "Failed to issue reset: %d\n", ret);
		return ret;
	}

	wm8944_handle_pdata(wm8944);

	wm8944_request_irq(wm8944->wm8944, WM8944_IRQ_LDO_UV, wm8944_ldo_warn,
			   "wm8944_ldo undervoltage", codec);
	wm8944_request_irq(wm8944->wm8944, WM8944_IRQ_TEMP, wm8944_temp_warn,
			   "wm8944_overtemperature", codec);

	ret = snd_soc_add_codec_controls(codec, wm8944_snd_controls,
					 ARRAY_SIZE(wm8944_snd_controls));
	if (ret) {
		dev_err(codec->dev, "Failed to issue WM8944 registers init.: %d\n", ret);
		return ret;
	}

	ret = wm8944_add_widgets(codec);
	if (ret) {
		return ret;
	}
#ifdef CONFIG_DEBUG_FS
	debug_wm8944_priv = wm8944;
#endif

	pm_runtime_get_sync(wm8944->wm8944->dev);

	return ret;
}

static int wm8944_codec_remove(struct snd_soc_codec *codec)
{
	int ret = 0;
	struct wm8944_priv *wm8944 = snd_soc_codec_get_drvdata(codec);

	wm8944_set_bias_level(codec, SND_SOC_BIAS_OFF);
	if (ret < 0) {
		dev_err(codec->dev, "%s Failed to unset bias: %d\n",
			__func__, ret);
		return ret;
	}
	pm_runtime_put_sync(wm8944->wm8944->dev);

	return ret;
}

static struct regmap* wm8944_get_regmap(struct device *dev)
{
	struct wm8944* control = dev_get_drvdata(dev->parent);

	return control->regmap;
}

static struct snd_soc_codec_driver soc_codec_dev_wm8944 = {
	.probe             = wm8944_codec_probe,
	.remove            = wm8944_codec_remove,
	.suspend           = wm8944_codec_suspend,
	.resume            = wm8944_codec_resume,
	.set_bias_level    = wm8944_set_bias_level,
	.get_regmap	   = wm8944_get_regmap,
};

#ifdef CONFIG_DEBUG_FS
static struct dentry *debugfs_poke;

static int codec_debug_open(struct inode *inode, struct file *file)
{
	file->private_data = inode->i_private;
	return 0;
}

static ssize_t codec_debug_write(struct file *filp,
				 const char __user *ubuf,
				 size_t cnt, loff_t *ppos)
{
	char lbuf[32];
	char *buf;
	int rc;

	if (cnt > sizeof(lbuf) - 1)
		return -EINVAL;

	rc = copy_from_user(lbuf, ubuf, cnt);
	if (rc)
		return -EFAULT;

	lbuf[cnt] = '\0';
	buf = (char *)lbuf;
	/*debug_wm8944_priv->no_mic_headset_override = (*strsep(&buf, " ") == '0')
	  ? false : true;*/

	return rc;
}

static const struct file_operations codec_debug_ops = {
	.open = codec_debug_open,
	.write = codec_debug_write,
};
#endif

static int wm8944_probe(struct platform_device *pdev)
{
	int ret = 0;
	struct wm8944_priv *wm8944;

#ifdef CONFIG_DEBUG_FS
	debugfs_poke = debugfs_create_file("TRRS",
					   S_IFREG | S_IRUGO, NULL,
					   (void *) "TRRS", &codec_debug_ops);

#endif
	wm8944 = devm_kzalloc(&pdev->dev, sizeof(struct wm8944_priv),
			      GFP_KERNEL);
	if (wm8944 == NULL)
		return -ENOMEM;
	platform_set_drvdata(pdev, wm8944);

	wm8944->wm8944 = dev_get_drvdata(pdev->dev.parent);
	wm8944->pdata = dev_get_platdata(pdev->dev.parent);


	INIT_WORK(&wm8944->work, wm8944_work);

	ret = snd_soc_register_codec(&pdev->dev, &soc_codec_dev_wm8944,
				     &wm8944_dai, 1);
	if (ret < 0)
		dev_err(&pdev->dev, "%s Registering failed: %d\n",
			__func__, ret);
	return ret;
}

static int wm8944_remove(struct platform_device *pdev)
{
	snd_soc_unregister_codec(&pdev->dev);
#ifdef CONFIG_DEBUG_FS
	debugfs_remove(debugfs_poke);
#endif
	return 0;
}

#ifdef CONFIG_PM_SLEEP
static const struct dev_pm_ops wm8944_pm_ops = {
	.suspend = wm8944_suspend,
	.resume  = wm8944_resume,
};
#endif

static struct platform_driver wm8944_codec_driver = {
	.driver = {
		.name = "wm8944-codec",
		.owner = THIS_MODULE,
#ifdef CONFIG_PM_SLEEP
		.pm = &wm8944_pm_ops,
#endif
	},
	.probe    = wm8944_probe,
	.remove   = wm8944_remove,
};

static int __init wm8944_codec_init(void)
{
	printk("%s registering platform driver\n", __func__);

	return platform_driver_register(&wm8944_codec_driver);
}
module_init(wm8944_codec_init);

static void __exit wm8944_codec_exit(void)
{
	platform_driver_unregister(&wm8944_codec_driver);
}
module_exit(wm8944_codec_exit);


MODULE_DESCRIPTION("ASoC WM8944 driver");
MODULE_AUTHOR("Jean Michel Chauvet/Gaetan Perrier");
MODULE_LICENSE("GPL");
MODULE_ALIAS("platform:wm8944-codec");
