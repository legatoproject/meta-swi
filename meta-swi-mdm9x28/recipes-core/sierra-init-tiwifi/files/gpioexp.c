/**
 * file gpio.c
 *
 * The GPIO implementation of GPIO Expander 1, 2, 3 on MangOH board
 *
 * Copyright (C) Sierra Wireless Inc. Use of this work is subject to license.
 */

#include <linux/i2c-dev.h>
#include <i2c/smbus.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/ioctl.h>

/**
 * i2c slave address on MangOH platform
 */
#define I2C_SX1509_GPIO_EXPANDER1_ADDR      0x3E
#define I2C_SX1509_GPIO_EXPANDER2_ADDR      0x3F
#define I2C_SX1509_GPIO_EXPANDER3_ADDR      0x70
#define I2C_SWITCH_PCA9548A_ADDR            0x71

/**
 * The pin IO definition of GPIO Expander1: IC U903.
 */
typedef enum
{
    MANGOH_GPIOEXPANDER_EXP1_PIN_ARDUINO_RESET_LEVEL,
    MANGOH_GPIOEXPANDER_EXP1_PIN_BATTCHRGR_PG_N,
    MANGOH_GPIOEXPANDER_EXP1_PIN_BATTGAUGE_GPIO,
    MANGOH_GPIOEXPANDER_EXP1_PIN_LED_ON,
    MANGOH_GPIOEXPANDER_EXP1_PIN_ATMEGA_RESET_GPIO,
    MANGOH_GPIOEXPANDER_EXP1_PIN_CONNECT_TO_AV_LED,
    MANGOH_GPIOEXPANDER_EXP1_PIN_PCM_ANALOG_SELECT,
    MANGOH_GPIOEXPANDER_EXP1_PIN_CONNECT_TO_AV,
    MANGOH_GPIOEXPANDER_EXP1_PIN_BOARD_REV_RES1,
    MANGOH_GPIOEXPANDER_EXP1_PIN_BOARD_REV_RES2,
    MANGOH_GPIOEXPANDER_EXP1_PIN_UART_EXP1_ENN,
    MANGOH_GPIOEXPANDER_EXP1_PIN_UART_EXP1_IN,
    MANGOH_GPIOEXPANDER_EXP1_PIN_UART_EXP2_IN,
    MANGOH_GPIOEXPANDER_EXP1_PIN_SDIO_SEL,
    MANGOH_GPIOEXPANDER_EXP1_PIN_SPI_EXP1_ENN,
    MANGOH_GPIOEXPANDER_EXP1_PIN_SPI_EXP1_IN
} mangoh_gpioExpander_Exp1Pin_t;

/**
 * The pin IO definition of GPIO Expander2: IC U906.
 */
typedef enum
{
    MANGOH_GPIOEXPANDER_EXP2_PIN_IOT0_GPIO3,
    MANGOH_GPIOEXPANDER_EXP2_PIN_IOT0_GPIO2,
    MANGOH_GPIOEXPANDER_EXP2_PIN_IOT0_GPIO1,
    MANGOH_GPIOEXPANDER_EXP2_PIN_IOT1_GPIO3,
    MANGOH_GPIOEXPANDER_EXP2_PIN_IOT1_GPIO2,
    MANGOH_GPIOEXPANDER_EXP2_PIN_IOT1_GPIO1,
    MANGOH_GPIOEXPANDER_EXP2_PIN_IOT2_GPIO3,
    MANGOH_GPIOEXPANDER_EXP2_PIN_IOT2_GPIO2,
    MANGOH_GPIOEXPANDER_EXP2_PIN_IOT2_GPIO1,
    MANGOH_GPIOEXPANDER_EXP2_PIN_SENSOR_INT1,
    MANGOH_GPIOEXPANDER_EXP2_PIN_SENSOR_INT2,
    MANGOH_GPIOEXPANDER_EXP2_PIN_CARD_DETECT_IOT0,
    MANGOH_GPIOEXPANDER_EXP2_PIN_CARD_DETECT_IOT2,
    MANGOH_GPIOEXPANDER_EXP2_PIN_CARD_DETECT_IOT1,
    MANGOH_GPIOEXPANDER_EXP2_PIN_SPI_EXP1_ENN,
    MANGOH_GPIOEXPANDER_EXP2_PIN_SPI_EXP1_IN
} mangoh_gpioExpander_Exp2Pin_t;

/**
 * The pin IO definition of GPIO Expander3: IC U909.
 */
typedef enum
{
    MANGOH_GPIOEXPANDER_EXP3_PIN_USB_HUB_INTN,
    MANGOH_GPIOEXPANDER_EXP3_PIN_HUB_CONNECT,
    MANGOH_GPIOEXPANDER_EXP3_PIN_GPIO_IOT2_RESET,
    MANGOH_GPIOEXPANDER_EXP3_PIN_GPIO_IOT1_RESET,
    MANGOH_GPIOEXPANDER_EXP3_PIN_GPIO_IOT0_RESET,
    MANGOH_GPIOEXPANDER_EXP3_PIN_IOT0_GPIO4,
    MANGOH_GPIOEXPANDER_EXP3_PIN_IOT1_GPIO4,
    MANGOH_GPIOEXPANDER_EXP3_PIN_IOT2_GPIO4,
    MANGOH_GPIOEXPANDER_EXP3_PIN_UART_EXP2_ENN,
    MANGOH_GPIOEXPANDER_EXP3_PIN_PCM_EXP1_ENN,
    MANGOH_GPIOEXPANDER_EXP3_PIN_PCM_EXP1_SEL,
    MANGOH_GPIOEXPANDER_EXP3_PIN_ARD_FTDI,
    MANGOH_GPIOEXPANDER_EXP3_PIN_LCD_ON_OFF,
    MANGOH_GPIOEXPANDER_EXP3_PIN_FAST_SIM_SWITCH,
    MANGOH_GPIOEXPANDER_EXP3_PIN_ARDUINO_USB_CTRL,
    MANGOH_GPIOEXPANDER_EXP3_PIN_RS232_ENABLE
} mangoh_gpioExpander_Exp3Pin_t;

/**
 * When using GPIO pins we first need to specify in which mode we'd like to use it.
 * There are three modes into which a pin can be set.
 *
 * The type of GPIO pin mode,  Input, Output.
 *
 */
typedef enum
{
    MANGOH_GPIOEXPANDER_PIN_MODE_OUTPUT,
    MANGOH_GPIOEXPANDER_PIN_MODE_INPUT,
} mangoh_gpioExpander_PinMode_t;

/**
 * The type of GPIO level low or high.
 */
typedef enum
{
    MANGOH_GPIOEXPANDER_ACTIVE_TYPE_LOW,
    MANGOH_GPIOEXPANDER_ACTIVE_TYPE_HIGH
} mangoh_gpioExpander_ActiveType_t;

typedef enum
{
    MANGOH_GPIOEXPANDER_POLARITY_TYPE_NORMAL,
    MANGOH_GPIOEXPANDER_POLARITY_TYPE_INVERSE
} mangoh_gpioExpander_PolarityType_t;

/**
 * The type of GPIO pullup, pulldown.
 *
 * PULLUPDOWN_TYPE_OFF:  pullup disable and pulldown disable
 * PULLUPDOWN_TYPE_DOWN: pullup disable and pulldown enable
 * PULLUPDOWN_TYPE_UP:   pullup enable and pulldown disable
 */
typedef enum
{
    MANGOH_GPIOEXPANDER_PULLUPDOWN_TYPE_OFF,
    MANGOH_GPIOEXPANDER_PULLUPDOWN_TYPE_DOWN,
    MANGOH_GPIOEXPANDER_PULLUPDOWN_TYPE_UP
} mangoh_gpioExpander_PullUpDownType_t;

/**
 * The operation of GPIO open drain
 */
typedef enum
{
    MANGOH_GPIOEXPANDER_PUSH_PULL_OP,
    MANGOH_GPIOEXPANDER_OPEN_DRAIN_OP
} mangoh_gpioExpander_OpenDrainOperation_t;

/**
 * gpio expander number on MangOH platform
 */
enum GpioExpanderNum {
    GPIO_EXPANDER_1 = 1,
    GPIO_EXPANDER_2,
    GPIO_EXPANDER_3,
    MAX_GPIO_EXPANDER_NR = GPIO_EXPANDER_3
};

/**
 * The SX1509 GPIO Register Address
 */
typedef enum {
    SX1509_GPIO_RegInputDisableB,
    SX1509_GPIO_RegPullUpB = 0x06,
    SX1509_GPIO_RegPullUpA = 0x07,
    SX1509_GPIO_RegPullDownB = 0x08,
    SX1509_GPIO_RegPullDownA = 0x09,
    SX1509_GPIO_RegOpenDrainB = 0x0A,
    SX1509_GPIO_RegOpenDrainA = 0x0B,
    SX1509_GPIO_RegPolarityB = 0x0C,
    SX1509_GPIO_RegPolarityA = 0x0D,
    SX1509_GPIO_RegDirB = 0x0E,
    SX1509_GPIO_RegDirA = 0x0F,
    SX1509_GPIO_RegDataB = 0x10,
    SX1509_GPIO_RegDataA = 0x11,
    SX1509_GPIO_RegInterruptMaskB = 0x12,
    SX1509_GPIO_RegInterruptMaskA = 0x13,
    SX1509_GPIO_RegSenseHighB = 0x14,
    SX1509_GPIO_RegSenseLowB = 0x15,
    SX1509_GPIO_RegSenseHighA = 0x16,
    SX1509_GPIO_RegSenseLowA = 0x17
}
Sc1509GpioExpanderRegs_t;

/**
 * The action to disable or enable of GPIO register pullup, pulldown.
 */
typedef enum {
    GPIO_PULLUP_DOWN_DISABLE,
    GPIO_PULLUP_DOWN_ENABLE
}
GpioPullUpDownAction;

/**
 * The struct of Expander object
 */
struct mangoh_gpioExpander_Gpio {
    unsigned char module;
    mangoh_gpioExpander_PinMode_t mode;
    mangoh_gpioExpander_ActiveType_t level;
    mangoh_gpioExpander_PullUpDownType_t pud;
    unsigned char pinNum;
    unsigned char i2cAddr;
    unsigned char i2cBus;
    unsigned char bank;
};
typedef struct mangoh_gpioExpander_Gpio *mangoh_gpioExpander_GpioRef_t;

/**
 * The gpio expander module structure for Expander 1, 2, and 3 object.
 */
static struct mangoh_gpioExpander_Gpio GpioObjModules[MAX_GPIO_EXPANDER_NR];

/**
 * Get i2c bus file descriptor and set i2c slave address.
 *
 * If parameter 'i2cAddr' is not 0, not necessary to control i2c slave address.
 *
 * return
 * - -1          In case of failure
 * - A positive value  The file descriptor of i2c bus
 */
static int SetI2cBusAddr
(
    int i2cBus,
    int i2cAddr
)
{
    int fd;
    size_t size;
    char filename[32];

    size = sizeof(filename);
    snprintf(filename, size, "/dev/i2c/%d", i2cBus);

    printf("Open I2C Bus at, '%s'\n", filename);
    fd = open(filename, O_RDWR);
    if (fd < 0 && (errno == ENOENT || errno == ENOTDIR)) {
        snprintf(filename, size, "/dev/i2c-%d", i2cBus);
        printf("Try open I2C Bus at, '%s'\n", filename);
        fd = open(filename, O_RDWR);
    }

    if (fd < 0) {
        if (errno == ENOENT) {
            fprintf(stderr, "ERR* ""Could not open file /dev/i2c-%d or /dev/i2c/%d: %s\n",
                    i2cBus, i2cBus, strerror(ENOENT));
        } else {
            fprintf(stderr, "ERR* ""Could not open file %s': %s\n", filename, strerror(errno));
        }

        return -1;
    }

    if (i2cAddr) {
        if (ioctl(fd, I2C_SLAVE_FORCE, i2cAddr) < 0) {
            fprintf(stderr, "ERR* ""Could not set address to 0x%02x: %s\n",i2cAddr, strerror(errno));
            return -1;
        }
    }

    return fd;
}

/**
 * Write a value across the i2c bus.
 *
 * return
 * - -1          The function failed.
 * - 0             The function succeeded.
 */
static int I2cSetAddrValue
(
    int i2cBus,
    int i2cAddr,
    int regAddr,
    int dataValue
)
{
    int i2cdev_fd;

    if ((i2cBus < 0) || (i2cAddr < 0) || (regAddr < 0) || (regAddr > 0xff)) {
        fprintf(stderr, "ERR* ""%d:%x:%x\n", i2cBus, i2cAddr, regAddr);
        return -1;
    }

    i2cdev_fd = SetI2cBusAddr(i2cBus, i2cAddr);
    if (i2cdev_fd == -1)
    {
        fprintf(stderr, "ERR* ""failed to open i2cbus %d\n", i2cBus);
        return -1;
    }

    if (i2c_smbus_write_byte_data(i2cdev_fd, regAddr, dataValue) < 0)
    {
        fprintf(stderr, "ERR* ""failed to write i2c data\n");
        close(i2cdev_fd);
        return -1;
    }

    close(i2cdev_fd);
    return 0;
}


/**
 * Read a value across the i2c bus.
 *
 * return
 * - -1          The function failed.
 * - Positive value    The function succeeded with return value from i2c register
 */
static int I2cGetAddrValue
(
    int i2cBus,
    int i2cAddr,
    int regAddr
)
{
    int val;
    int i2cdev_fd;

    if ((i2cBus < 0) || (i2cAddr < 0) || (regAddr < 0) || (regAddr > 0xff)) {
        fprintf(stderr, "ERR* ""%d:%x:%x\n", i2cBus, i2cAddr, regAddr);
        return -1;
    }

    i2cdev_fd = SetI2cBusAddr(i2cBus, i2cAddr);
    if (i2cdev_fd == -1) {
        fprintf(stderr, "ERR* ""failed to open i2cbus %d\n", i2cBus);
        return -1;
    }
    val = i2c_smbus_read_byte_data(i2cdev_fd, regAddr);
    if (val < 0)
    {
        fprintf(stderr, "ERR* ""failed to read i2c data\n");
        close(i2cdev_fd);
        return -1;
    }

    close(i2cdev_fd);
    return val;
}

/**
 * Get the pin number for this IO and convert it to the bit index in the appropriate bank register.
 *
 * There are two banks of 8 I/O pins: A and B.
 * The lowest bit of the register address (daddr) is the bank select: 0 = B, 1 = A.
 * Bank B: IO[15-8] or Bank A: IO[7-0]
 *
 * return
 * - A positive value  The bit index at bank A or B
 */
static unsigned char PinNumToBankIndex(unsigned char num)
{
    unsigned char index;

    index = num < 8 ? num : (num - 8);
    return index;
}

/**
 * Based on expander object GPIO number, get register bank value
 *
 * return
 * - -1          The function failed.
 * - A unsigned charean value   The bit value of GPIO pin number
 */
static int GetRegVal(mangoh_gpioExpander_GpioRef_t gpioRefPtr, unsigned char regAddr)
{
    unsigned char regNew;
    unsigned char bit;

    regNew = (regAddr | gpioRefPtr->bank);

    unsigned char index = PinNumToBankIndex(gpioRefPtr->pinNum);
    unsigned char pinMask = 1 << index;

    // Read the current register values.
    int regVal = I2cGetAddrValue(gpioRefPtr->i2cBus, gpioRefPtr->i2cAddr, regNew);
    if (regVal == -1)
    {
        fprintf(stderr, "ERR* ""I2c get addr 0x%x value failure\n", gpioRefPtr->i2cAddr);
        return -1;
    }

    regVal &= pinMask;
    bit = regVal >> index;

    printf("\tRegister Addr 0x%x: 0x%x...bit:%d\n", regNew, regVal, bit);

    return bit;
}

/**
 * Based on expander object GPIO number, set register bank value
 *
 * return
 * - -1          The function failed.
 * - 0             The function succeeded.
 */
static int SetRegVal
(
    mangoh_gpioExpander_GpioRef_t gpioRefPtr,
    unsigned char regAddr,
    unsigned char value
)
{
    unsigned char regNew;

    regNew = (regAddr | gpioRefPtr->bank);

    unsigned char index = PinNumToBankIndex(gpioRefPtr->pinNum);
    unsigned char pinMask = 1 << index;

    // Read the current register values.
    int regVal = I2cGetAddrValue(gpioRefPtr->i2cBus, gpioRefPtr->i2cAddr, regNew);
    if (regVal == -1)
    {
        fprintf(stderr, "ERR* ""I2c get addr 0x%x value failure", gpioRefPtr->i2cAddr);
        return -1;
    }

    regVal &= ~pinMask;
    regVal |= (value << index);
    if (I2cSetAddrValue(gpioRefPtr->i2cBus, gpioRefPtr->i2cAddr, regNew, regVal) != 0)
    {
        fprintf(stderr, "ERR* ""I2c set address value 0x%x failure", regAddr);
        return -1;
    }

    printf("\tRegister Addr 0x%x: 0x%x...\n", regNew, regVal);

    return 0;
}

/**
 * setup GPIO Direction INPUT or OUTPUT mode.
 *
 * return
 * - -1          The function failed.
 * - 0             The function succeeded.
 */
int mangoh_gpioExpander_SetDirectionMode ( mangoh_gpioExpander_GpioRef_t gpioRefPtr,
                                           mangoh_gpioExpander_PinMode_t mode )
{
    printf("mode:%s\n", (mode == MANGOH_GPIOEXPANDER_PIN_MODE_OUTPUT) ? "Output": "Input");
    if (SetRegVal(gpioRefPtr, SX1509_GPIO_RegDirB, mode) != 0)
    {
        fprintf(stderr, "ERR* ""Set mode %d failure", mode);
        return -1;
    }

    printf("Succesfully setup direction mode\n");
    return 0;
}

/**
 * Request GPIO object from GPIO function module and GPIO pin number.
 *
 * return
 * - A positive value  this will return a newly created gpio reference.
 * - NULL if request failed to provide valid expander and pin number.
 */
mangoh_gpioExpander_GpioRef_t mangoh_gpioExpander_Request ( unsigned char module, unsigned char pinNum )
{
    if (module > MAX_GPIO_EXPANDER_NR || module < GPIO_EXPANDER_1)
    {
        fprintf( stderr,"Supplied bad (%d) GPIO Expander number\n", module);
        return NULL;
    }

    if (pinNum > 15)
    {
        fprintf( stderr,"Supplied bad (%d) GPIO Pin number", pinNum);
        return NULL;
    }

    mangoh_gpioExpander_GpioRef_t gpioRefPtr = &GpioObjModules[module - 1];

    gpioRefPtr->module = module;
    gpioRefPtr->pinNum = pinNum;

    if (module == GPIO_EXPANDER_1)
    {
        gpioRefPtr->i2cAddr = I2C_SX1509_GPIO_EXPANDER1_ADDR;
    }
    else if(module == GPIO_EXPANDER_2)
    {
        gpioRefPtr->i2cAddr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
    }
    else if(module == GPIO_EXPANDER_3)
    {
        gpioRefPtr->i2cAddr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
    }
    gpioRefPtr->i2cBus = 4;

    gpioRefPtr->bank = 1; // 1 = A
    if (pinNum > 7)
    {
        gpioRefPtr->bank = 0; // 0 = B
    }

    printf("expander#:%d gpio pin:%d, i2cAddr:0x%x\n", gpioRefPtr->module, gpioRefPtr->pinNum, gpioRefPtr->i2cAddr);

    return gpioRefPtr;
}

/**
 * Release GPIO Module object
 *
 * return
 * - -1          The function failed.
 * - 0             The function succeeded.
 */
int mangoh_gpioExpander_Release ( mangoh_gpioExpander_GpioRef_t gpioRefPtr )
{
    gpioRefPtr->pinNum = -1;

    return 0;
}

/**
 * setup GPIO pullup or pulldown disable/enable.
 *
 * return
 * - -1          The function failed.
 * - 0             The function succeeded.
 */
int mangoh_gpioExpander_SetPullUpDown( mangoh_gpioExpander_GpioRef_t gpioRefPtr,
                                       mangoh_gpioExpander_PullUpDownType_t pud )
{
    if (pud == MANGOH_GPIOEXPANDER_PULLUPDOWN_TYPE_OFF) {
        printf("Pulldown/pullup type OFF\n");
        if (SetRegVal(gpioRefPtr, SX1509_GPIO_RegPullUpB, GPIO_PULLUP_DOWN_DISABLE) != 0)
        {
            fprintf(stderr, "ERR* ""Set pullup disable failure\n");
            return -1;
        }
        if (SetRegVal(gpioRefPtr, SX1509_GPIO_RegPullDownB, GPIO_PULLUP_DOWN_DISABLE) != 0)
        {
            fprintf(stderr, "ERR* ""Set pulldown disable failure\n");
            return -1;
        }
    } else if (pud == MANGOH_GPIOEXPANDER_PULLUPDOWN_TYPE_DOWN) {
        printf("Pulldown type enable\n");
        if (SetRegVal(gpioRefPtr, SX1509_GPIO_RegPullUpB, GPIO_PULLUP_DOWN_DISABLE) != 0)
        {
            fprintf(stderr, "ERR* ""Set pullup disable failure\n");
            return -1;
        }
        if (SetRegVal(gpioRefPtr, SX1509_GPIO_RegPullDownB, GPIO_PULLUP_DOWN_ENABLE) != 0)
        {
            fprintf(stderr, "ERR* ""Set pulldown enable failure\n");
            return -1;
        }
    } else if (pud == MANGOH_GPIOEXPANDER_PULLUPDOWN_TYPE_UP) {
        printf("Pullup type enable\n");
        if (SetRegVal(gpioRefPtr, SX1509_GPIO_RegPullUpB, GPIO_PULLUP_DOWN_ENABLE) != 0)
        {
            fprintf(stderr, "ERR* ""Set pullup enable failure\n");
            return -1;
        }
        if (SetRegVal(gpioRefPtr, SX1509_GPIO_RegPullDownB, GPIO_PULLUP_DOWN_DISABLE) != 0)
        {
            fprintf(stderr, "ERR* ""Set pulldown disable failure\n");
            return -1;
        }
    }

    return 0;
}

/**
 * setup GPIO OpenDrain.
 *
 * Enables open drain operation for each output-configured IO.
 *
 * Output pins can be driven in two different modes:
 * - Regular push-pull operation: A transistor connects to high, and a transistor connects to low
 *   (only one is operated at a time)
 * - Open drain operation:  A transistor connects to low and nothing else
 *
 * return
 * - -1          The function failed.
 * - 0             The function succeeded.
 */
int mangoh_gpioExpander_SetOpenDrain( mangoh_gpioExpander_GpioRef_t gpioRefPtr,
                                      mangoh_gpioExpander_OpenDrainOperation_t drainOp )
{
    printf("enable open drain:%s\n", (drainOp==1) ? "Open drain operation": "Regular push-pull operation");
    if (SetRegVal(gpioRefPtr, SX1509_GPIO_RegOpenDrainB, drainOp) != 0)
    {
        fprintf(stderr, "ERR* ""Set opendrain %d failure\n", drainOp);
        return -1;
    }

    return 0;
}

/**
 * setup GPIO polarity.
 *
 * return
 * - -1          The function failed.
 * - 0             The function succeeded.
 */
int mangoh_gpioExpander_SetPolarity( mangoh_gpioExpander_GpioRef_t gpioRefPtr,
                                     mangoh_gpioExpander_PolarityType_t level )
{
    printf("level:%s\n", (level==1) ? "inverse": "normal");
    if (SetRegVal(gpioRefPtr, SX1509_GPIO_RegPolarityB, level) != 0)
    {
        fprintf(stderr, "ERR* ""Set polarity %d failure\n", level);
        return -1;
    }

    return 0;
}

/**
 * write value to GPIO output mode, low or high
 *
 * return
 * - -1          The function failed.
 * - 0             The function succeeded.
 */
int mangoh_gpioExpander_Output( mangoh_gpioExpander_GpioRef_t gpioRefPtr,
                                mangoh_gpioExpander_ActiveType_t level )
{
    printf("active:%s\n", (level==1) ? "high": "low");
    if (SetRegVal(gpioRefPtr, SX1509_GPIO_RegDataB, level) != 0)
    {
        fprintf(stderr, "ERR* ""Set output %d failure\n", level);
        return -1;
    }

    return 0;
}

/**
 * read value from GPIO input mode.
 *
 * return
 *      An active type, the status of pin: HIGH or LOW
 */
mangoh_gpioExpander_ActiveType_t mangoh_gpioExpander_Input( mangoh_gpioExpander_GpioRef_t gpioRefPtr )
{
    mangoh_gpioExpander_ActiveType_t type;

    type = (mangoh_gpioExpander_ActiveType_t)GetRegVal(gpioRefPtr, SX1509_GPIO_RegDataB);
    printf("read active type:%s\n", (type==1) ? "high": "low");

    return type;
}

int main( int argc, char **argv )
{
    int file;
    int i2c_addr;
    int daddr;
    int data;
    int i;
    int ret = 0;
    const int i2cbus = 4;
    unsigned char reg, val;

    int expander, gpio;
    mangoh_gpioExpander_GpioRef_t gpiop = NULL;

    // -1: initialize the pin number of gpio module, the module is not initialized
    for (i = 0; i < MAX_GPIO_EXPANDER_NR; i++)
        GpioObjModules[i].pinNum = -1;

    if( argc < 3 ) {
      fprintf( stderr, "Usage: %s expander gpio [...options...]\n", argv[0] );
      exit( 2 );
    }

    sscanf( argv[1], "%u", &expander );
    sscanf( argv[2], "%u", &gpio );

    gpiop = mangoh_gpioExpander_Request( expander, gpio );
    if( !gpiop ) {
      fprintf( stderr, "Unknown expander %u or gpio %u\n", expander, gpio );
      exit( 2 );
    }
    printf( "module %d, pin %d i2cAddr %d bus %d bank %d\n",
            gpiop->module, gpiop->pinNum, gpiop->i2cAddr, gpiop->i2cBus, gpiop->bank );

    for( i = 3; i < argc; i++ ) {
      if( 0 == strcmp( argv[i], "input" ) )
        ret = mangoh_gpioExpander_SetDirectionMode( gpiop, MANGOH_GPIOEXPANDER_PIN_MODE_INPUT );
      else if( 0 == strcmp( argv[i], "output" ) )
        ret = mangoh_gpioExpander_SetDirectionMode( gpiop, MANGOH_GPIOEXPANDER_PIN_MODE_OUTPUT );
      else if( 0 == strcmp( argv[i], "low" ) )
        ret = mangoh_gpioExpander_Output( gpiop, MANGOH_GPIOEXPANDER_ACTIVE_TYPE_LOW );
      else if( 0 == strcmp( argv[i], "high" ) )
        ret = mangoh_gpioExpander_Output( gpiop, MANGOH_GPIOEXPANDER_ACTIVE_TYPE_HIGH );
      else if( 0 == strcmp( argv[i], "inverse" ) )
        ret = mangoh_gpioExpander_SetPolarity( gpiop, MANGOH_GPIOEXPANDER_POLARITY_TYPE_INVERSE );
      else if( 0 == strcmp( argv[i], "normal" ) )
        ret = mangoh_gpioExpander_SetPolarity( gpiop, MANGOH_GPIOEXPANDER_POLARITY_TYPE_NORMAL );
      else if( 0 == strcmp( argv[i], "down" ) )
        ret = mangoh_gpioExpander_SetPullUpDown( gpiop, MANGOH_GPIOEXPANDER_PULLUPDOWN_TYPE_DOWN );
      else if( 0 == strcmp( argv[i], "up" ) )
        ret = mangoh_gpioExpander_SetPullUpDown( gpiop, MANGOH_GPIOEXPANDER_PULLUPDOWN_TYPE_UP );
      else if( 0 == strcmp( argv[i], "off" ) )
        ret = mangoh_gpioExpander_SetPullUpDown( gpiop, MANGOH_GPIOEXPANDER_PULLUPDOWN_TYPE_OFF );
      else if( 0 == strcmp( argv[i], "opendrain" ) )
        ret = mangoh_gpioExpander_SetOpenDrain( gpiop, MANGOH_GPIOEXPANDER_OPEN_DRAIN_OP );
      else if( 0 == strcmp( argv[i], "pushpull" ) )
        ret = mangoh_gpioExpander_SetOpenDrain( gpiop, MANGOH_GPIOEXPANDER_PUSH_PULL_OP );
      else if( 0 == strcmp( argv[i], "value" ) )
        printf( "%d\n", mangoh_gpioExpander_Input( gpiop ) );
      else if( 0 == strcmp( argv[i], "regval" ) ) {
        if( i < (argc - 1) && (1 == sscanf( argv[i+1], "%hhX", &reg )) ) {
          printf( "%02x\n", GetRegVal( gpiop, reg ) );
          i++;
        }
      }
      else if( 0 == strcmp( argv[i], "enable" ) ) {
        file = SetI2cBusAddr(i2cbus, 0);
        if (file == -1)
        {
            fprintf(stderr,"FTL* ""Failed to set i2c bus address\n");
            exit( 1 );
        }

        // Enable the I2C switch.
        printf("Enabling PCA9548A I2C switch...\n");
        i2c_addr = I2C_SWITCH_PCA9548A_ADDR;
        daddr = 0xf9; //1111 1111 (enable all I2C channels)
        data = -1;
        if (I2cSetAddrValue(i2cbus, i2c_addr, daddr, data) == -1)
        {
            fprintf(stderr,"FTL* ""Failed to enable PCA9548A I2C switch\n");
            exit( 1 );
        }
        else
        {
            printf("PCA9548A I2C switch enabled.\n");
        }
        // wait to make sure the i2c switch has been enabled
        sleep(1);

        close( file );
      }
      else {
        fprintf( stderr, "Unknown option '%s'\n", argv[i] );
        exit( 2 );
      }
    }

  exit( ret ? 3 : 0 );
}
