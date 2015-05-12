/**
 * i2cgpioctl.c - a user-space program to control GPIO pin on MangOH platform
 *
 * Author: Vincent Zhu - vzhu@sierrawireless.com
 */

#include <errno.h>
#include <string.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include "tools/i2c-dev.h"
#include "i2cbusses.h"
#include "version.h"

/* i2c slave address on MangOH platform */
#define I2C_SWITCH_PCA9548A_ADDR            0x71
#define I2C_USB3503_ADDR                    0x08
#define I2C_SX1509_GPIO_EXPANDER1_ADDR      0x3E
#define I2C_SX1509_GPIO_EXPANDER2_ADDR      0x3F
#define I2C_SX1509_GPIO_EXPANDER3_ADDR      0x70
#define I2C_IOT_CARD_LOW_ADDR               0x52
#define I2C_IOT_CARD_HIGH_ADDR              0x53
#define I2C_LSM6DS0_ADDR                    0x6A
#define I2C_BATTERY_BQ24292I_ADDR           0x6B

#define MODE_AUTO    0
#define MODE_QUICK   1
#define MODE_READ    2
#define MODE_FUNC    3

#define EXIT                                                    0
#define SCAN_I2C_BUS                                            1
#define ENABLE_PCA9548A_I2C_SWITCH_CHANNEL_IOT0_CARD            (SCAN_I2C_BUS + 1)
#define DISABLE_PCA9548A_I2C_SWITCH_CHANNEL                     3
#define INPUT_SX1509_GPIO_EXPANDER2_IOT0_2                      4
#define OUTPUT_SX1509_GPIO_EXPANDER2_IOT0_2                     5
#define IOT_CARD_OUTPUT_I2C_ADDR_DETECT                         6
#define IOT_CARD_INPUT_I2C_ADDR_DETECT                          7
#define SX1509_GPIO_EXPANDER1_I2C_ADDR_DETECT                   8
#define SX1509_GPIO_EXPANDER2_I2C_ADDR_DETECT                   9
#define SX1509_GPIO_EXPANDER3_I2C_ADDR_DETECT                  10
#define USB3503_I2C_ADDR_DETECT                                11
#define BQ24292I_BATTERY_I2C_ADDR_DETECT                       12
#define LSM6DS0_3D_I2C_ADDR_DETECT                             13
#define ENABLE_EXPANDER2_IOT0_GPIO1_LED_D1                     14
#define ENABLE_EXPANDER2_IOT0_GPIO2_LED_D2                     15
#define ENABLE_EXPANDER2_IOT0_GPIO3_LED_D3                     16
#define ENABLE_EXPANDER3_IOT0_GPIO4_LED_D4                     17
#define ENABLE_EXPANDER2_IOT1_GPIO1_LED_D1                     18
#define ENABLE_EXPANDER2_IOT1_GPIO2_LED_D2                     19
#define ENABLE_EXPANDER2_IOT1_GPIO3_LED_D3                     20
#define ENABLE_EXPANDER3_IOT1_GPIO4_LED_D4                     21
#define ENABLE_EXPANDER2_IOT2_GPIO1_LED_D1                     22
#define ENABLE_EXPANDER2_IOT2_GPIO2_LED_D2                     23
#define ENABLE_EXPANDER2_IOT2_GPIO3_LED_D3                     24
#define ENABLE_EXPANDER3_IOT2_GPIO4_LED_D4                     25
#define DISABLE_EXPANDER2_IOT0_GPIO1_LED_D1                    26
#define DISABLE_EXPANDER2_IOT0_GPIO2_LED_D2                    27
#define DISABLE_EXPANDER2_IOT0_GPIO3_LED_D3                    28
#define DISABLE_EXPANDER3_IOT0_GPIO4_LED_D4                    29
#define DISABLE_EXPANDER2_IOT1_GPIO1_LED_D1                    30
#define DISABLE_EXPANDER2_IOT1_GPIO2_LED_D2                    31
#define DISABLE_EXPANDER2_IOT1_GPIO3_LED_D3                    32
#define DISABLE_EXPANDER3_IOT1_GPIO4_LED_D4                    33
#define DISABLE_EXPANDER2_IOT2_GPIO1_LED_D1                    34
#define DISABLE_EXPANDER2_IOT2_GPIO2_LED_D2                    35
#define DISABLE_EXPANDER2_IOT2_GPIO3_LED_D3                    36
#define DISABLE_EXPANDER3_IOT2_GPIO4_LED_D4                    37
#define DETECT_GPIO_EXPANDER2_IOT0_CARD_INSERT_REMOVE          38
#define DETECT_GPIO_EXPANDER2_IOT1_CARD_INSERT_REMOVE          39
#define DETECT_GPIO_EXPANDER2_IOT2_CARD_INSERT_REMOVE          40
#define DETECT_GPIO_EXPANDER2_GPIO_EXP3_INTERRUPT              41
#define DETECT_GPIO_EXPANDER2_BATTERY_CHARGER_INTERRUPT        42
#define ENABLE_PCA9548A_I2C_SWITCH_CHANNEL_IOT1_CARD           43
#define ENABLE_PCA9548A_I2C_SWITCH_CHANNEL_IOT2_CARD           44
#define GPIO_EXPANDER1_IO5_ENABLE_ARDUINO_SPI_CONTROL_SWITCH   55
#define GPIO_EXPANDER1_IO7_ENABLE_ARDUINO_I2C_CONTROL_SWITCH   57
#define DETECT_GPIO_EXPANDER3_IO0_USB_HUB_INTERRUPT            70
#define GPIO_ENABLE_UART2_RS232                                85
#define GPIO_ENABLE_UART1_IOT0                                 86
#define GPIO_ENABLE_UART1_IOT1                                 87
#define GPIO_ENABLE_UART1_IOT2                                 88

#define SOFTWARE_RESET_GPIO_EXPANDER1_DEVICE                   90
#define SOFTWARE_RESET_GPIO_EXPANDER2_DEVICE                   91
#define SOFTWARE_RESET_GPIO_EXPANDER3_DEVICE                   92
#define LIST_I2C_BUSES                                         93
#define CLEAR_DEFAULT_CONFIGURATION                            99
#define LOAD_DEFAULT_CONFIGURATION                            100

static void help(void)
{
    fprintf(stderr,
        "i2cgpioctl tool for Sierra Wireless MangOH platform\n"
        "Usage: i2cgpioctl \n");
}

static int check_i2c_bus_slave_addr(int file, int mode, int i2c_addr)
{
    int res;

    /* Set slave address */
    if (ioctl(file, I2C_SLAVE, i2c_addr) < 0) {
        if (errno == EBUSY) {
            printf("\t Address is busy!");
        } else {
            printf("Error: Could not set "
                "address to 0x%02x\n", i2c_addr);
            return -1;
        }
    }

    /* Probe this address */
    switch (mode) {
        case MODE_QUICK:
            res = i2c_smbus_write_quick(file, I2C_SMBUS_WRITE);
            break;
        case MODE_READ:
            res = i2c_smbus_read_byte(file);
            break;
        default:
            if ((i2c_addr >= 0x30 && i2c_addr <= 0x37)
                || (i2c_addr >= 0x50 && i2c_addr <= 0x5F))
                res = i2c_smbus_read_byte(file);
            else
                res = i2c_smbus_write_quick(file,
                          I2C_SMBUS_WRITE);
    }

    return res;
}

static int i2c_set_addr_value(int i2cbus, int slave_addr, int daddr, int data_value)
{
    int ret = -1;
    char filename[32];
    int i2cdev_fd;
    int force = 1;
    int size = I2C_SMBUS_BYTE_DATA;
    int len = 0;
    int block = 0;

    if ((i2cbus < 0) || (slave_addr < 0) || (daddr < 0) || (daddr > 0xff)) {
        printf("Error in i2c_set_addr: %d:%x:%x\n",
            i2cbus, slave_addr, daddr);
        return ret;
    }
    if (data_value < 0)
        size = I2C_SMBUS_BYTE;

    if (size == I2C_SMBUS_BYTE_DATA && data_value > 0xff) {
        printf("Error: Data value out of range!\n");
        return ret;
    }

    i2cdev_fd = open_i2c_dev(i2cbus, filename, sizeof(filename), 0);
    if (i2cdev_fd < 0) {
        printf("Error: failed to open i2cbus %d\n", i2cbus);
        return ret;
    }
    set_slave_addr(i2cdev_fd, slave_addr, force);

    switch (size) {
    case I2C_SMBUS_BYTE:
        ret = i2c_smbus_write_byte(i2cdev_fd, daddr);
        break;
    case I2C_SMBUS_WORD_DATA:
        ret = i2c_smbus_write_word_data(i2cdev_fd, daddr, data_value);
        break;
    case I2C_SMBUS_BLOCK_DATA:
        ret = i2c_smbus_write_block_data(i2cdev_fd, daddr, len, block);
        break;
    case I2C_SMBUS_I2C_BLOCK_DATA:
        ret = i2c_smbus_write_i2c_block_data(i2cdev_fd, daddr, len, block);
        break;
    default: /* I2C_SMBUS_BYTE_DATA */
        ret = i2c_smbus_write_byte_data(i2cdev_fd, daddr, data_value);
        break;
    }

    close(i2cdev_fd);
    return ret;
}


static int i2c_get_addr_value(int i2cbus, int slave_addr, int daddr)
{
    int ret = -1;
    char filename[32];
    int i2cdev_fd;
    int force = 1;
    int size = I2C_SMBUS_BYTE_DATA;

    if ((i2cbus < 0) || (slave_addr < 0) || (daddr < 0) || (daddr > 0xff)) {
        printf("Error in i2c_set_addr: %d:%x:%x\n",
            i2cbus, slave_addr, daddr);
        return ret;
    }

    i2cdev_fd = open_i2c_dev(i2cbus, filename, sizeof(filename), 0);
    if (i2cdev_fd < 0) {
        printf("Error: failed to open i2cbus %d\n", i2cbus);
        return ret;
    }
    set_slave_addr(i2cdev_fd, slave_addr, force);

    switch (size) {
    case I2C_SMBUS_BYTE:
        ret = i2c_smbus_read_byte(i2cdev_fd);
        break;
    case I2C_SMBUS_WORD_DATA:
        ret = i2c_smbus_read_word_data(i2cdev_fd, daddr);
        break;
    default: /* I2C_SMBUS_BYTE_DATA */
        ret = i2c_smbus_read_byte_data(i2cdev_fd, daddr);
        break;
    }

    close(i2cdev_fd);
    return ret;
}

static int scan_i2c_bus(int file, int mode, int first, int last)
{
    int i, j;
    int res;

    printf("     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f\n");

    for (i = 0; i < 128; i += 16) {
        printf("%02x: ", i);
        for(j = 0; j < 16; j++) {
            fflush(stdout);

            /* Skip unwanted addresses */
            if (i+j < first || i+j > last) {
                printf("   ");
                continue;
            }

            /* Set slave address */
            if (ioctl(file, I2C_SLAVE, i+j) < 0) {
                if (errno == EBUSY) {
                    printf("UU ");
                    continue;
                } else {
                    fprintf(stderr, "Error: Could not set "
                        "address to 0x%02x: %s\n", i+j,
                        strerror(errno));
                    return -1;
                }
            }

            /* Probe this address */
            switch (mode) {
            case MODE_QUICK:
                /* This is known to corrupt the Atmel AT24RF08
                   EEPROM */
                res = i2c_smbus_write_quick(file,
                      I2C_SMBUS_WRITE);
                break;
            case MODE_READ:
                /* This is known to lock SMBus on various
                   write-only chips (mainly clock chips) */
                res = i2c_smbus_read_byte(file);
                break;
            default:
                if ((i+j >= 0x30 && i+j <= 0x37)
                 || (i+j >= 0x50 && i+j <= 0x5F))
                    res = i2c_smbus_read_byte(file);
                else
                    res = i2c_smbus_write_quick(file,
                          I2C_SMBUS_WRITE);
            }

            if (res < 0)
                printf("-- ");
            else
                printf("%02x ", i+j);
        }
        printf("\n");
    }

    return 0;
}

struct func
{
    long value;
    const char* name;
};

static const struct func all_func[] = {
    { .value = I2C_FUNC_I2C,
      .name = "I2C" },
    { .value = I2C_FUNC_SMBUS_QUICK,
      .name = "SMBus Quick Command" },
    { .value = I2C_FUNC_SMBUS_WRITE_BYTE,
      .name = "SMBus Send Byte" },
    { .value = I2C_FUNC_SMBUS_READ_BYTE,
      .name = "SMBus Receive Byte" },
    { .value = I2C_FUNC_SMBUS_WRITE_BYTE_DATA,
      .name = "SMBus Write Byte" },
    { .value = I2C_FUNC_SMBUS_READ_BYTE_DATA,
      .name = "SMBus Read Byte" },
    { .value = I2C_FUNC_SMBUS_WRITE_WORD_DATA,
      .name = "SMBus Write Word" },
    { .value = I2C_FUNC_SMBUS_READ_WORD_DATA,
      .name = "SMBus Read Word" },
    { .value = I2C_FUNC_SMBUS_PROC_CALL,
      .name = "SMBus Process Call" },
    { .value = I2C_FUNC_SMBUS_WRITE_BLOCK_DATA,
      .name = "SMBus Block Write" },
    { .value = I2C_FUNC_SMBUS_READ_BLOCK_DATA,
      .name = "SMBus Block Read" },
    { .value = I2C_FUNC_SMBUS_BLOCK_PROC_CALL,
      .name = "SMBus Block Process Call" },
    { .value = I2C_FUNC_SMBUS_PEC,
      .name = "SMBus PEC" },
    { .value = I2C_FUNC_SMBUS_WRITE_I2C_BLOCK,
      .name = "I2C Block Write" },
    { .value = I2C_FUNC_SMBUS_READ_I2C_BLOCK,
      .name = "I2C Block Read" },
    { .value = 0, .name = "" }
};

static void print_functionality(unsigned long funcs)
{
    int i;

    for (i = 0; all_func[i].value; i++) {
        printf("%-32s %s\n", all_func[i].name,
               (funcs & all_func[i].value) ? "yes" : "no");
    }
}

/*
 * Print the installed i2c busses. The format is those of Linux 2.4's
 * /proc/bus/i2c for historical compatibility reasons.
 */
static void print_i2c_busses(void)
{
    struct i2c_adap *adapters;
    int count;

    adapters = gather_i2c_busses();
    if (adapters == NULL) {
        fprintf(stderr, "Error: Out of memory!\n");
        return;
    }

    for (count = 0; adapters[count].name; count++) {
        printf("i2c-%d\t%-10s\t%-32s\t%s\n",
            adapters[count].nr, adapters[count].funcs,
            adapters[count].name, adapters[count].algo);
    }

    free_adapters(adapters);
}

void cmd_usage(void)
{
    int cmd_cnt = 1;

    printf("\nHello Sir, What would you like to do? \n");
    printf("\t 0. Exit\n");
    printf("\t %d. Scan i2c bus\n", cmd_cnt++);
    printf("\t %d. Enable PCA9548A I2C switch channel IOT0 Card\n", cmd_cnt++);
    printf("\t %d. Disable PCA9548A I2C switch channel\n", cmd_cnt++);
    printf("\t %d. Enable SX1509 GPIO Expander2 input for IOT0-2 Card\n", cmd_cnt++);
    printf("\t %d. Enable SX1509 GPIO Expander2 output for IOT0-2 Card\n", cmd_cnt++);
    printf("\t %d. Detect output high IOT i2c slave address\n", cmd_cnt++);
    printf("\t %d. Detect IOT low i2c slave address\n", cmd_cnt++);
    printf("\t %d. Detect SX1509 GPIO Expander1 i2c slave address\n", cmd_cnt++);
    printf("\t %d. Detect SX1509 GPIO Expander2 i2c slave address\n", cmd_cnt++);
    printf("\t %d. Detect SX1509 GPIO Expander3 i2c slave address\n", cmd_cnt++);
    printf("\t %d. Detect USB3503 i2c slave address\n", cmd_cnt++);
    printf("\t %d. Detect BQ24292I Battery i2c slave address\n", cmd_cnt++);
    printf("\t %d. Detect LSM6DS0 3D i2c slave address\n", cmd_cnt++);
    printf("\t %d. Enable GPIO Expander2 IOT0 GPIO1 LED D1 Light\n", cmd_cnt++);
    printf("\t %d. Enable GPIO Expander2 IOT0 GPIO2 LED D2 Light\n", cmd_cnt++);
    printf("\t %d. Enable GPIO Expander2 IOT0 GPIO3 LED D3 Light\n", cmd_cnt++);
    printf("\t %d. Enable GPIO Expander3 IOT0 GPIO4 LED D4 Light\n", cmd_cnt++);
    printf("\t %d. Enable GPIO Expander2 IOT1 GPIO1 LED D1 Light\n", cmd_cnt++);
    printf("\t %d. Enable GPIO Expander2 IOT1 GPIO2 LED D2 Light\n", cmd_cnt++);
    printf("\t %d. Enable GPIO Expander2 IOT1 GPIO3 LED D3 Light\n", cmd_cnt++);
    printf("\t %d. Enable GPIO Expander3 IOT1 GPIO4 LED D4 Light\n", cmd_cnt++);
    printf("\t %d. Enable GPIO Expander2 IOT2 GPIO1 LED D1 Light\n", cmd_cnt++);
    printf("\t %d. Enable GPIO Expander2 IOT2 GPIO2 LED D2 Light\n", cmd_cnt++);
    printf("\t %d. Enable GPIO Expander2 IOT2 GPIO3 LED D3 Light\n", cmd_cnt++);
    printf("\t %d. Enable GPIO Expander3 IOT2 GPIO4 LED D4 Light\n", cmd_cnt++);
    printf("\t %d. Disable GPIO Expander2 IOT0 GPIO1 LED D1 Light\n", cmd_cnt++);
    printf("\t %d. Disable GPIO Expander2 IOT0 GPIO2 LED D2 Light\n", cmd_cnt++);
    printf("\t %d. Disable GPIO Expander2 IOT0 GPIO3 LED D3 Light\n", cmd_cnt++);
    printf("\t %d. Disable GPIO Expander3 IOT0 GPIO4 LED D4 Light\n", cmd_cnt++);
    printf("\t %d. Disable GPIO Expander2 IOT1 GPIO1 LED D1 Light\n", cmd_cnt++);
    printf("\t %d. Disable GPIO Expander2 IOT1 GPIO2 LED D2 Light\n", cmd_cnt++);
    printf("\t %d. Disable GPIO Expander2 IOT1 GPIO3 LED D3 Light\n", cmd_cnt++);
    printf("\t %d. Disable GPIO Expander3 IOT1 GPIO4 LED D4 Light\n", cmd_cnt++);
    printf("\t %d. Disable GPIO Expander2 IOT2 GPIO1 LED D1 Light\n", cmd_cnt++);
    printf("\t %d. Disable GPIO Expander2 IOT2 GPIO2 LED D2 Light\n", cmd_cnt++);
    printf("\t %d. Disable GPIO Expander2 IOT2 GPIO3 LED D3 Light\n", cmd_cnt++);
    printf("\t %d. Disable GPIO Expander3 IOT2 GPIO4 LED D4 Light\n", cmd_cnt++);
    printf("\t %d. Detect GPIO Expander2 IOT0 card insert/remove action\n", cmd_cnt++);
    printf("\t %d. Detect GPIO Expander2 IOT1 card insert/remove action\n", cmd_cnt++);
    printf("\t %d. Detect GPIO Expander2 IOT2 card insert/remove action\n", cmd_cnt++);
    printf("\t %d. Detect GPIO Expander2 EXP3 IO14 Interrupt\n", cmd_cnt++);
    printf("\t %d. Detect GPIO Expander2 Battery Charger IO15 Interrupt\n", cmd_cnt++);
    printf("\t %d. Enable PCA9548A I2C switch channel IOT1 Card\n", cmd_cnt++);
    printf("\t %d. Enable PCA9548A I2C switch channel IOT2 Card\n", cmd_cnt++);
    printf("\t 55. GPIO Expander1 IO5 Arduino spi control switch\n");
    printf("\t 57. GPIO Expander1 IO7 Arduino i2c control switch\n");
    printf("\t 70. Detect GPIO Expander3 IO0 USB Hub Interrupt\n");
    printf("\t 85. GPIO Expander(#1, #3) Enable UART2(RS232)\n");
    printf("\t 86. GPIO Expander Enable UART1 IOT0 Module\n");
    printf("\t 87. GPIO Expander Enable UART1 IOT1 Module\n");
    printf("\t 88. GPIO Expander Enable UART1 IOT2 Module\n");
    printf("\t 90. Software Reset GPIO Expander1 Device\n");
    printf("\t 91. Software Reset GPIO Expander2 Device\n");
    printf("\t 92. Software Reset GPIO Expander3 Device\n");
    printf("\t 93. List i2c buses\n");
    printf("\t 99. Clear default configuraiton\n");
    printf("\t 100. Loading default configuraiton\n");

    return;
}

int main(int argc, char *argv[])
{
    char *end;
    int i2cbus, file, res;
    int i2c_addr, daddr, data;
    char filename[20];
    unsigned long funcs;
    int mode = MODE_AUTO;
    int first = 0x03, last = 0x77;

    printf("i2cgpioctl tool for Sierra Wireless MangOH platform\n\n");

    mode = MODE_READ;
    i2cbus = 0;

    file = open_i2c_dev(i2cbus, filename, sizeof(filename), 0);
    if (file < 0) {
        exit(1);
    }

    if (ioctl(file, I2C_FUNCS, &funcs) < 0) {
        fprintf(stderr, "Error: Could not get the adapter "
            "functionality matrix: %s\n", strerror(errno));
        close(file);
        exit(1);
    }

    /* Special case, we only list the implemented functionalities */
    if (mode == MODE_FUNC) {
        close(file);
        printf("Functionalities implemented by %s:\n", filename);
        print_functionality(funcs);
        exit(0);
    }

    if (mode != MODE_READ && !(funcs & I2C_FUNC_SMBUS_QUICK)) {
        fprintf(stderr, "Error: Can't use SMBus Quick Write command "
            "on this bus\n");
        close(file);
        exit(1);
    }
    if (mode != MODE_QUICK && !(funcs & I2C_FUNC_SMBUS_READ_BYTE)) {
        fprintf(stderr, "Error: Can't use SMBus Read Byte command "
            "on this bus\n");
        close(file);
        exit(1);
    }

    unsigned char ch;
    unsigned char mask_bit;
    int exit_flag = 0;
    int read_val = 0;
    while(1) {
        int cmd;

        cmd_usage();

        printf("Input option (1-100): ");
        scanf("%d", &cmd);
        printf("\n");

        switch (cmd) {
            case SCAN_I2C_BUS:
                printf("Scanning i2c bus...\n");
                res = scan_i2c_bus(file, mode, first, last);
                printf("Done\n");
                break;

            case ENABLE_PCA9548A_I2C_SWITCH_CHANNEL_IOT0_CARD:
                printf("Enabling PCA9548A I2C switch channel IOT0 Card...\n");
                i2c_addr = I2C_SWITCH_PCA9548A_ADDR;
                daddr = 0xf9; //1111 1001, IOT0
                data = -1;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case ENABLE_PCA9548A_I2C_SWITCH_CHANNEL_IOT1_CARD:
                printf("Enabling PCA9548A I2C switch channel IOT1 Card...\n");
                i2c_addr = I2C_SWITCH_PCA9548A_ADDR;
                daddr = 0xfa; //1111 1010, IOT1
                data = -1;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case ENABLE_PCA9548A_I2C_SWITCH_CHANNEL_IOT2_CARD:
                printf("Enabling PCA9548A I2C switch channel IOT2 Card...\n");
                i2c_addr = I2C_SWITCH_PCA9548A_ADDR;
                daddr = 0xfc; //1111 1100, IOT2
                data = -1;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DISABLE_PCA9548A_I2C_SWITCH_CHANNEL:
                printf("Disabling PCA9548A I2C switch channel...\n");
                i2c_addr = I2C_SWITCH_PCA9548A_ADDR;
                daddr = 0x00;
                data = -1;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case INPUT_SX1509_GPIO_EXPANDER2_IOT0_2:
                printf("Enabling SX1509 GPIO Expander2 input for IOT0-2 Card...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0e;  // Direction B
                data = 0x38;   // 0011 1000
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case OUTPUT_SX1509_GPIO_EXPANDER2_IOT0_2:
                printf("Enabling SX1509 GPIO Expander2 output for IOT0-2 Card...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0e;  // Direction B
                data = 0xc7;   // 1100 0111
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case IOT_CARD_OUTPUT_I2C_ADDR_DETECT:
                printf("Detecting output high IOT i2c slave address...\n");
                i2c_addr = I2C_IOT_CARD_HIGH_ADDR;
                res = check_i2c_bus_slave_addr(file, mode, i2c_addr);
                if (res < 0) {
                    printf("\t0x%x Not Detected!\n", i2c_addr);
                } else {
                    printf("\t0x%x Detected!\n\n", i2c_addr);
                }
                printf("Done\n");
                break;

            case IOT_CARD_INPUT_I2C_ADDR_DETECT:
                printf("Detecting IOT low i2c slave address...\n");
                i2c_addr = I2C_IOT_CARD_LOW_ADDR;
                res = check_i2c_bus_slave_addr(file, mode, i2c_addr);
                if (res < 0) {
                    printf("\t0x%x Not Detected!\n", i2c_addr);
                } else {
                    printf("\t0x%x Detected!\n\n", i2c_addr);
                }
                printf("Done\n");
                break;

            case SX1509_GPIO_EXPANDER1_I2C_ADDR_DETECT:
                printf("Detecting SX1509 GPIO Expander1 i2c slave address...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER1_ADDR;
                res = check_i2c_bus_slave_addr(file, mode, i2c_addr);
                if (res < 0) {
                    printf("\t0x%x Not Detected!\n", i2c_addr);
                } else {
                    printf("\t0x%x Detected!\n\n", i2c_addr);
                }
                printf("Done\n");
                break;

            case SX1509_GPIO_EXPANDER2_I2C_ADDR_DETECT:
                printf("Detecting SX1509 GPIO Expander2 i2c slave address...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                res = check_i2c_bus_slave_addr(file, mode, i2c_addr);
                if (res < 0) {
                    printf("\t0x%x Not Detected!\n", i2c_addr);
                } else {
                    printf("\t0x%x Detected!\n\n", i2c_addr);
                }
                printf("Done\n");
                break;


            case SX1509_GPIO_EXPANDER3_I2C_ADDR_DETECT:
                printf("Detecting SX1509 GPIO Expander3 i2c slave address...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
                res = check_i2c_bus_slave_addr(file, mode, i2c_addr);
                if (res < 0) {
                    printf("\t0x%x Not Detected!\n", i2c_addr);
                } else {
                    printf("\t0x%x Detected!\n\n", i2c_addr);
                }
                printf("Done\n");
                break;

            case USB3503_I2C_ADDR_DETECT:
                printf("Detecting USB3503 i2c slave address...\n");
                i2c_addr = I2C_USB3503_ADDR;
                res = check_i2c_bus_slave_addr(file, mode, i2c_addr);
                if (res < 0) {
                    printf("\t0x%x Not Detected!\n", i2c_addr);
                } else {
                    printf("\t0x%x Detected!\n\n", i2c_addr);
                }
                printf("Done\n");
                break;

            case BQ24292I_BATTERY_I2C_ADDR_DETECT:
                printf("Detecting BQ24292I Battery i2c slave address...\n");
                i2c_addr = I2C_BATTERY_BQ24292I_ADDR;
                res = check_i2c_bus_slave_addr(file, mode, i2c_addr);
                if (res < 0) {
                    printf("\t0x%x Not Detected!\n", i2c_addr);
                } else {
                    printf("\t0x%x Detected!\n\n", i2c_addr);
                }
                printf("Done\n");
                break;

            case LSM6DS0_3D_I2C_ADDR_DETECT:
                printf("Detecting LSM6DS0 3D i2c slave address...\n");
                i2c_addr = I2C_LSM6DS0_ADDR;
                res = check_i2c_bus_slave_addr(file, mode, i2c_addr);
                if (res < 0) {
                    printf("\t0x%x Not Detected!\n", i2c_addr);
                } else {
                    printf("\t0x%x Detected!\n\n", i2c_addr);
                }
                printf("Done\n");
                break;

            case ENABLE_EXPANDER2_IOT0_GPIO1_LED_D1:
                printf("Enabling GPIO Expander2 IOT0 GPIO1 LED D1 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0xfb;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x04;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case ENABLE_EXPANDER2_IOT0_GPIO2_LED_D2:
                printf("Enabling GPIO Expander2 IOT0 GPIO2 LED D2 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0xfd;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x02;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case ENABLE_EXPANDER2_IOT0_GPIO3_LED_D3:
                printf("Enabling GPIO Expander2 IOT0 GPIO3 LED D3 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0xfe;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x01;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case ENABLE_EXPANDER3_IOT0_GPIO4_LED_D4:
                printf("Enabling GPIO Expander3 IOT0 GPIO4 LED D4 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0xdf;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x20;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case ENABLE_EXPANDER2_IOT1_GPIO1_LED_D1:
                printf("Enabling GPIO Expander2 IOT1 GPIO1 LED D1 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0xdf;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x20;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case ENABLE_EXPANDER2_IOT1_GPIO2_LED_D2:
                printf("Enabling GPIO Expander2 IOT1 GPIO2 LED D2 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0xef;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x10;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case ENABLE_EXPANDER2_IOT1_GPIO3_LED_D3:
                printf("Enabling GPIO Expander2 IOT1 GPIO3 LED D3 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0xf7;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x08;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case ENABLE_EXPANDER3_IOT1_GPIO4_LED_D4:
                printf("Enabling GPIO Expander3 IOT1 GPIO4 LED D4 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0xbf;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x40;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case ENABLE_EXPANDER2_IOT2_GPIO1_LED_D1:
                printf("Enabling GPIO Expander2 IOT2 GPIO1 LED D1 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x7f;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x80;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case ENABLE_EXPANDER2_IOT2_GPIO2_LED_D2:
                printf("Enabling GPIO Expander2 IOT2 GPIO2 LED D2 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0xbf;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x40;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case ENABLE_EXPANDER2_IOT2_GPIO3_LED_D3:
                printf("Enabling GPIO Expander2 IOT2 GPIO3 LED D3 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0e; //RegDirB
                data = 0xfe;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0c; //RegPolarityB
                data = 0x01;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case ENABLE_EXPANDER3_IOT2_GPIO4_LED_D4:
                printf("Enabling GPIO Expander3 IOT2 GPIO4 LED D4 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x7f;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x80;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DISABLE_EXPANDER2_IOT0_GPIO1_LED_D1:
                printf("Disabling GPIO Expander2 IOT0 GPIO1 LED D1 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x00;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x00;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DISABLE_EXPANDER2_IOT0_GPIO2_LED_D2:
                printf("Disabling GPIO Expander2 IOT0 GPIO2 LED D2 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x00;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x00;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DISABLE_EXPANDER2_IOT0_GPIO3_LED_D3:
                printf("Disabling GPIO Expander2 IOT0 GPIO3 LED D3 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x00;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x00;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DISABLE_EXPANDER3_IOT0_GPIO4_LED_D4:
                printf("Disabling GPIO Expander3 IOT0 GPIO4 LED D4 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x00;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x00;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DISABLE_EXPANDER2_IOT1_GPIO1_LED_D1:
                printf("Disabling GPIO Expander2 IOT1 GPIO1 LED D1 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x00;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x00;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DISABLE_EXPANDER2_IOT1_GPIO2_LED_D2:
                printf("Disabling GPIO Expander2 IOT1 GPIO2 LED D2 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x00;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x00;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DISABLE_EXPANDER2_IOT1_GPIO3_LED_D3:
                printf("Disabling GPIO Expander2 IOT1 GPIO3 LED D3 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x00;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x00;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DISABLE_EXPANDER3_IOT1_GPIO4_LED_D4:
                printf("Disabling GPIO Expander3 IOT1 GPIO4 LED D4 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x00;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x00;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DISABLE_EXPANDER2_IOT2_GPIO1_LED_D1:
                printf("Disabling GPIO Expander2 IOT2 GPIO1 LED D1 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x00;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x00;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DISABLE_EXPANDER2_IOT2_GPIO2_LED_D2:
                printf("Disabling GPIO Expander2 IOT2 GPIO2 LED D2 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x00;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x00;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DISABLE_EXPANDER2_IOT2_GPIO3_LED_D3:
                printf("Disabling GPIO Expander2 IOT2 GPIO3 LED D3 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0e; //RegDirB
                data = 0x00;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0c; //RegPolarityB
                data = 0x00;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DISABLE_EXPANDER3_IOT2_GPIO4_LED_D4:
                printf("Disabling GPIO Expander3 IOT2 GPIO4 LED D4 Light...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x00;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0x00;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case DETECT_GPIO_EXPANDER2_IOT0_CARD_INSERT_REMOVE:
                printf("Detecting GPIO Expander2 IOT0 card insert/remove action...\n");
                mask_bit = 0x08;

                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0e; //RegDirB
                data = 0x38; //Input
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x12; //RegInterruptMaskB
                data = 0; //trigger an interrupt
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x14; //RegSenseHighB
                data = 0xff; //Both Rising and Falling
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x15; //RegSenseLowB
                data = 0xff; //Both Rising and Falling
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x18; //RegInterruptSourceB
                ch = getchar();
                while(1) {
                    printf("\tInsert/Remove IOT0 Card now, then press 'Enter' key\n");
                    while(1) {
                        ch = getchar();
                        if (ch == '\n')
                            break;
                    }
                    read_val = i2c_get_addr_value(i2cbus, i2c_addr, daddr);
                    if (read_val & mask_bit) {
                        daddr = 0x10; //RegDataB
                        read_val = i2c_get_addr_value(i2cbus, i2c_addr, daddr);
                        if (read_val & 0x08)
                            printf("\tDetected - Card Removed\n\n");
                        else
                            printf("\tDetected - Card Inserted\n\n");
                        break;
                    } else {
                        printf("\tNot Detected \n\n");
                    }
                }

                daddr = 0x18; //RegInterruptSourceB
                data = 0xff; //Clear Interrupt
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                break;

            case DETECT_GPIO_EXPANDER2_IOT1_CARD_INSERT_REMOVE:
                printf("Detecting GPIO Expander2 IOT1 card insert/remove action...\n");
                mask_bit = 0x20;

                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0e; //RegDirB
                data = 0x38; //Input
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x12; //RegInterruptMaskB
                data = 0; //trigger an interrupt
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x14; //RegSenseHighB
                data = 0xff; //Both Rising and Falling
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x15; //RegSenseLowB
                data = 0xff; //Both Rising and Falling
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x18; //RegInterruptSourceB
                ch = getchar();
                while(1) {
                    printf("\tInsert/Remove IOT1 Card now, then press 'Enter' key\n");
                    while(1) {
                        ch = getchar();
                        if (ch == '\n')
                            break;
                    }
                    read_val = i2c_get_addr_value(i2cbus, i2c_addr, daddr);
                    if (read_val & mask_bit) {
                        daddr = 0x10; //RegDataB
                        read_val = i2c_get_addr_value(i2cbus, i2c_addr, daddr);
                        if (read_val & 0x20)
                            printf("\tDetected - Card Removed\n\n");
                        else
                            printf("\tDetected - Card Inserted\n\n");
                        break;
                    } else {
                        printf("\tNot Detected \n\n");
                    }
                }

                daddr = 0x18; //RegInterruptSourceB
                data = 0xff; //Clear Interrupt
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                break;

            case DETECT_GPIO_EXPANDER2_IOT2_CARD_INSERT_REMOVE:
                printf("Detecting GPIO Expander2 IOT2 card insert/remove action...\n");
                mask_bit = 0x10;

                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0e; //RegDirB
                data = 0x38; //Input
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x12; //RegInterruptMaskB
                data = 0; //trigger an interrupt
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x14; //RegSenseHighB
                data = 0xff; //Both Rising and Falling
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x15; //RegSenseLowB
                data = 0xff; //Both Rising and Falling
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x18; //RegInterruptSourceB
                ch = getchar();
                while(1) {
                    printf("\tInsert/Remove IOT2 Card now, then press 'Enter' key\n");
                    while(1) {
                        ch = getchar();
                        if (ch == '\n')
                            break;
                    }
                    read_val = i2c_get_addr_value(i2cbus, i2c_addr, daddr);
                    if (read_val & mask_bit) {
                        daddr = 0x10; //RegDataB
                        read_val = i2c_get_addr_value(i2cbus, i2c_addr, daddr);
                        if (read_val & 0x10)
                            printf("\tDetected - Card Removed\n\n");
                        else
                            printf("\tDetected - Card Inserted\n\n");
                        break;
                    } else {
                        printf("\tNot Detected \n\n");
                    }
                }

                daddr = 0x18; //RegInterruptSourceB
                data = 0xff; //Clear Interrupt
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                break;

            case DETECT_GPIO_EXPANDER2_GPIO_EXP3_INTERRUPT:
                printf("Detecting GPIO Expander2 EXP3 Interrupt...\n");
                mask_bit = 0x40;

                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0e; //RegDirB
                data = 0x40; //Input
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x12; //RegInterruptMaskB
                data = 0; //trigger an interrupt
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x14; //RegSenseHighB
                data = 0xff; //Both Rising and Falling
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x15; //RegSenseLowB
                data = 0xff; //Both Rising and Falling
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x18; //RegInterruptSourceB
                ch = getchar();
                while(1) {
                    printf("\tGet GPIO EXP3 interrupt now, then press 'Enter' key\n");
                    while(1) {
                        ch = getchar();
                        if (ch == '\n')
                            break;
                    }
                    read_val = i2c_get_addr_value(i2cbus, i2c_addr, daddr);
                    if (read_val & mask_bit) {
                        printf("\tDetected!\n\n");
                        break;
                    } else {
                        printf("\tNot Detected \n\n");
                    }
                }

                daddr = 0x18; //RegInterruptSourceB
                data = 0xff; //Clear Interrupt
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                break;

            case DETECT_GPIO_EXPANDER2_BATTERY_CHARGER_INTERRUPT:
                printf("Detecting GPIO Expander2 Battery Charger Interrupt...\n");
                mask_bit = 0x80;

                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0e; //RegDirB
                data = mask_bit; //Input
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x12; //RegInterruptMaskB
                data = 0; //trigger an interrupt
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x14; //RegSenseHighB
                data = 0xff; //Both Rising and Falling
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x15; //RegSenseLowB
                data = 0xff; //Both Rising and Falling
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x18; //RegInterruptSourceB
                ch = getchar();
                while(1) {
                    printf("\tGet Battery Charger now, then press 'Enter' key\n");
                    while(1) {
                        ch = getchar();
                        if (ch == '\n')
                            break;
                    }
                    read_val = i2c_get_addr_value(i2cbus, i2c_addr, daddr);
                    if (read_val & mask_bit) {
                        printf("\tDetected!\n\n");
                        break;
                    } else {
                        printf("\tNot Detected \n\n");
                    }
                }

                daddr = 0x18; //RegInterruptSourceB
                data = 0xff; //Clear Interrupt
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                break;

            case GPIO_EXPANDER1_IO5_ENABLE_ARDUINO_SPI_CONTROL_SWITCH:
                printf("GPIO Expander1 IO5 Arduino spi control switch...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER1_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0xdf; //0 as output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                break;

            case GPIO_EXPANDER1_IO7_ENABLE_ARDUINO_I2C_CONTROL_SWITCH:
                printf("GPIO Expander1 IO7 Arduino i2c control switch...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER1_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x7f; //0 as output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                break;

            case DETECT_GPIO_EXPANDER3_IO0_USB_HUB_INTERRUPT:
                printf("Detecting GPIO Expander3 IO0 USB Hub Interrupt...\n");
                mask_bit = 0x01;

                i2c_addr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
                daddr = 0x0f; //RegDirA
                data = mask_bit; //Input
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x13; //RegInterruptMaskA
                data = 0; //trigger an interrupt
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x16; //RegSenseHighA
                data = 0xff; //Both Rising and Falling
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x17; //RegSenseLowA
                data = 0xff; //Both Rising and Falling
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x19; //RegInterruptSourceA
                ch = getchar();
                while(1) {
                    printf("\tGet USB Hub interrupt now, then press 'Enter' key\n");
                    while(1) {
                        ch = getchar();
                        if (ch == '\n')
                            break;
                    }
                    read_val = i2c_get_addr_value(i2cbus, i2c_addr, daddr);
                    if (read_val & mask_bit) {
                        printf("\tDetected!\n\n");
                        break;
                    } else {
                        printf("\tNot Detected \n\n");
                    }
                }

                daddr = 0x19; //RegInterruptSourceA
                data = 0xff; //Clear Interrupt
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                break;

            case GPIO_ENABLE_UART2_RS232:
                printf("GPIO Enable UART2 RS232...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER1_ADDR;
                daddr = 0x0e; //RegDirB
                data = 0xff; //UART_EXP2_IN(low)
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                    break;
                }

                i2c_addr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
                daddr = 0x0e; //RegDirB
                data = 0x0f; //RS232 enable(high), UART_EXP2_EN(low)
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                break;

            case GPIO_ENABLE_UART1_IOT0:
                printf("GPIO Enable UART1 IOT0 Module...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER1_ADDR;
                daddr = 0x0e; //RegDirB
                data = 0xc0; //IO10, UART_EXP1_EN(low)
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }

                break;

            case GPIO_ENABLE_UART1_IOT1:
                printf("GPIO Enable UART1 IOT1 Module...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER1_ADDR;
                daddr = 0x0e; //RegDirB
                data = 0xc0; //IO11, UART_EXP1_IN(low)
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }

                break;

            case GPIO_ENABLE_UART1_IOT2:
                printf("GPIO Enable UART1 IOT2 Module...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
                daddr = 0x0e; //RegDirB
                data = 0xff; //IO12, UART_EXP2_EN(low)
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }

                break;

            case SOFTWARE_RESET_GPIO_EXPANDER1_DEVICE:
                printf("Software Reset GPIO Expander1 Device...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER1_ADDR;
                daddr = 0x7d; //RegReset
                data = 0x12;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x7d; //RegReset
                data = 0x34;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case SOFTWARE_RESET_GPIO_EXPANDER2_DEVICE:
                printf("Software Reset GPIO Expander2 Device...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x7d; //RegReset
                data = 0x12;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x7d; //RegReset
                data = 0x34;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case SOFTWARE_RESET_GPIO_EXPANDER3_DEVICE:
                printf("Software Reset GPIO Expander3 Device...\n");
                i2c_addr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
                daddr = 0x7d; //RegReset
                data = 0x12;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x7d; //RegReset
                data = 0x34;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                printf("Done\n");
                break;

            case LIST_I2C_BUSES:
                printf("List i2c buses...\n");
                print_i2c_busses();
                break;

            case CLEAR_DEFAULT_CONFIGURATION:
                printf("Clearing default configuraiton...\n");

                // Reset GPIO Expander1
                i2c_addr = I2C_SX1509_GPIO_EXPANDER1_ADDR;
                daddr = 0x7d; //RegReset
                data = 0x12;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x7d; //RegReset
                data = 0x34;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                // Reset GPIO Expander2
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x7d; //RegReset
                data = 0x12;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x7d; //RegReset
                data = 0x34;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                // Reset GPIO Expander3
                i2c_addr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
                daddr = 0x7d; //RegReset
                data = 0x12;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x7d; //RegReset
                data = 0x34;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                // Disable PC9548A i2c switch
                i2c_addr = I2C_SWITCH_PCA9548A_ADDR;
                daddr = 0x00;
                data = -1;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                break;

            case LOAD_DEFAULT_CONFIGURATION:
                printf("Loading default configuraiton...\n");

                // enable i2c switch, IOT0
                i2c_addr = I2C_SWITCH_PCA9548A_ADDR;
                daddr = 0xf9; //1111 1001, IOT0
                data = -1;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                // enable GPIO Expander2 LED1-3
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x0;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0xff;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                // enable GPIO Expander2 IOT2 GPIO3
                i2c_addr = I2C_SX1509_GPIO_EXPANDER2_ADDR;
                daddr = 0x0e; //RegDirB
                data = 0xfe;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0c; //RegPolarityB
                data = 0x01;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                // enable GPIO Expander3 LED4
                i2c_addr = I2C_SX1509_GPIO_EXPANDER3_ADDR;
                daddr = 0x0f; //RegDirA
                data = 0x00;  //Output
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);

                daddr = 0x0d; //RegPolarityA
                data = 0xff;
                res = i2c_set_addr_value(i2cbus, i2c_addr, daddr, data);
                if (res < 0) {
                    printf("\tFailed\n");
                } else {
                    printf("\tSuccessed!\n\n");
                }
                break;

            case EXIT:
                printf("Exit\n");
                exit_flag = 1;
                break;

            default:
                printf("Not supported command %d, try again!\n", cmd);
                printf("i2cgpioctl tool for Sierra Wireless MangOH platform\n\n");
                break;
        }
        if (exit_flag)
            break;
        sleep(3);
    }

    close(file);

    exit(0);
}

