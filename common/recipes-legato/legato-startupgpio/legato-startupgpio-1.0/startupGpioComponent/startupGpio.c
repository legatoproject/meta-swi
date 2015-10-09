//--------------------------------------------------------------------------------------------------
/**
 * @file startupGpio.c
 *
 * This file contains the source code of the startupGpio app.
 * This application set the GPIO1 to the value 1 when launched. It is used to
 * measure the startup time of a legato application start.
 *
 * Note that to the GPIO1 should be allocated to the APP/Linux core. To do so,
 * it is required to enter the command AT+WIOCFG=1,16;!RESET
 *
 * Copyright (C) Sierra Wireless Inc. Use of this work is subject to license.
 */
//--------------------------------------------------------------------------------------------------

#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>

#include "legato.h"

#ifndef STARTUP_GPIO_NUM
#define STARTUP_GPIO_NUM 1
#endif

#define STARTUP_GPIO_PATH "/sys/class/gpio/gpio"

COMPONENT_INIT
{
    int fdGpio;
    int rc;
    char gpioPath[ PATH_MAX ] = { '\0' };

    snprintf( gpioPath, sizeof(gpioPath),
              "%s%d/value", STARTUP_GPIO_PATH, STARTUP_GPIO_NUM );
    // check if GPIO1 is already exported under sysfs
    if( 0 > access( gpioPath, W_OK ) ) {
        char gpioStr[4] = { '\0' };

        // No, try to export it
        if( 0 > (fdGpio = open( "/sys/class/gpio/export", O_WRONLY )) ) {
            LE_ERROR( "Unable to open gpio/export: %m\n" );
            exit( 1 );
        }
        snprintf( gpioStr, sizeof(gpioStr), "%d\n", STARTUP_GPIO_NUM );
        rc = write( fdGpio, gpioStr, strlen(gpioStr) );
        close( fdGpio );
        if( strlen(gpioStr) != rc ) {
            LE_ERROR( "Write to gpio/export failed: %m\n" );
            LE_ERROR( "You need to do a AT+WIOCFG=%d,16 to allocate the GPIO%d\n",
                      STARTUP_GPIO_NUM, STARTUP_GPIO_NUM );
            exit( 1 );
        }

        // Export fails. The GPIO1 need to be allocated to the APP/Linux core
        // This requires a "AT+WIOCFG=1,16;!RESET" command
        snprintf( gpioPath, sizeof(gpioPath),
                  "%s%d/direction", STARTUP_GPIO_PATH, STARTUP_GPIO_NUM );
        if( 0 > (fdGpio = open( gpioPath, O_WRONLY )) ) {
            LE_ERROR( "Unable to open gpio%d/direction: %m\n", STARTUP_GPIO_NUM );
            exit( 1 );
        }
        // Set GPIO1 in output mode
        rc = write( fdGpio, "out\n", 4 );
        close( fdGpio );
        if( 4 != rc ) {
            LE_ERROR( "Write to gpio%d/direction failed: %m\n", STARTUP_GPIO_NUM );
            exit( 1 );
        }
        snprintf( gpioPath, sizeof(gpioPath),
                  "%s%d/value", STARTUP_GPIO_PATH, STARTUP_GPIO_NUM );
    }

    if( 0 > (fdGpio = open( gpioPath, O_WRONLY )) ) {
            LE_ERROR( "Unable to open gpio1/value: %m\n" );
            exit( 1 );
    }
    // Write the value 1 (set)
    rc = write( fdGpio, "1\n", 2 );
    close( fdGpio );
    if( 2 != rc ) {
        LE_ERROR( "Write to gpio%d/value failed: %m\n", STARTUP_GPIO_NUM );
        exit( 1 );
    }
    LE_INFO( "startupGpio has run ok :)\n" );

    exit( 0 );
}
