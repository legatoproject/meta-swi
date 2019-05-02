/*
********************************************************************************
* Name:  sierra_ks_if_dmv_test.c
*
* Sierra Wireless keystore userland test file.
*
* License Mozilla Public License Version 2.0
*
*===============================================================================
* Copyright (C) 2019 Sierra Wireless Inc.
********************************************************************************
*/

#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <sys/mman.h>
#include <string.h>
#include <sys/ioctl.h>
#include <unistd.h>
#include <getopt.h>
#include <errno.h>
#include <sys/times.h>
#include "sierra_ks_if_intf.h"

#define VERSION "1.0"

static char system_device[]="/dev/"SIERRA_KS_IF_DRV_NAME;
static char *this_e = NULL;

/* Local  */
static void dmv_read_rootfs_key(void);
static void dmv_read_legatofs_key(void);

int main (int argc, char **argv)
{
    int ret_ok = 0;
    int ret_err = 1;
    int ret = ret_ok;

    /* For option parsing. */
    extern char *optarg;

    this_e = argv[0];

    while(1) {

        extern char *optarg;
        extern int optind, opterr, optopt;
        int c;
        int option_index = 0;
        static struct option long_options[] = {
            {"RFS", 0, NULL, '1'},
            {"LG0", 0, NULL, '2'},
            {NULL,0,NULL,0}, /* Must be terminated because it segfaults on
                                incorrect entry. */
        };

        /* Get some long options */
        c = getopt_long(argc, argv, "h23", &long_options[0], &option_index);

        /* Exit while loop on error. */
        if(c == (-1)) {
            break;
        }

        /* Lets see what we can do about the opptions passed to us. */
        switch(c) {

            case '1':
            {
                dmv_read_rootfs_key();
            }
            break;

            case '2':
            {
                dmv_read_legatofs_key();
            }
            break;

            default:
            {
                printf("Invalid request\n");
            }
            break;
        }
    }

    return ret;
}

/* Request RFS dm-verity key from the kernel. */
void dmv_read_rootfs_key(void)
{
    int ret = 0;
    int fd = -1;
    ssize_t rlen;
    sierra_ks_if_drv_msg drv_msg;
    char *buf = (unsigned char *)(&drv_msg);

    /* Open keystore device. */
    fd = open(system_device, O_RDWR | O_SYNC);
    if( fd == -1) {
//        printf("(%s): Can't open '%s'.\n", __FUNCTION__, system_device);
        return;
    }

    /* Initialize driver storage. */
    memset((void*)(&drv_msg), 0, sizeof(drv_msg));

    /* We will play the tricks here and send the message to driver using read. */
    drv_msg.msg_type = SIERRA_KS_IF_DRV_MSG_TYPE_KEY_REQ;
    drv_msg.msg_subtype = SIERRA_KS_IF_DRV_MSG_TYPE_DM_VERITY_KEY_RFS_REQ;
    drv_msg.seq = 0;

    /* Tell the driver what's the size of the message we are sending. */
    drv_msg.pl_msg_sz = 0;

    /* Total size of the message we are sending via read. */
    rlen = sizeof(drv_msg.msg_type) + sizeof(drv_msg.msg_subtype) +
                 sizeof(drv_msg.seq) + sizeof(drv_msg.pl_msg_sz) + drv_msg.pl_msg_sz;
    rlen = read(fd, buf, rlen);
    if(rlen > 0) {
        if(drv_msg.msg_type == SIERRA_KS_IF_DRV_MSG_TYPE_KEY_RSP) {
            if(drv_msg.msg_subtype == SIERRA_KS_IF_DRV_MSG_TYPE_DM_VERITY_KEY_RFS_RSP) {
                printf("%s\n", drv_msg.payload);
            }
        }
    }
    else {
//        printf("Driver returned an error: 0x%lx\n", rlen);
    }

    /* Close the device. */
    close(fd);
}

/* Request Legato dm-verity key from the kernel. */
void dmv_read_legatofs_key(void)
{
    int ret = 0;
    int fd = -1;
    ssize_t rlen;
    sierra_ks_if_drv_msg drv_msg;
    char *buf = (unsigned char *)(&drv_msg);

    /* Open keystore device. */
    fd = open(system_device, O_RDWR | O_SYNC);
    if( fd == -1) {
        return;
    }

    /* Initialize driver storage. */
    memset((void*)(&drv_msg), 0, sizeof(drv_msg));

    drv_msg.msg_type = SIERRA_KS_IF_DRV_MSG_TYPE_KEY_REQ;
    drv_msg.msg_subtype = SIERRA_KS_IF_DRV_MSG_TYPE_DM_VERITY_KEY_LGT_REQ;
    drv_msg.seq = 0;

    /* Tell the driver what's the size of the message we are sending. */
    drv_msg.pl_msg_sz = 0;

    /* Total size of the message we are sending via read. */
    rlen = sizeof(drv_msg.msg_type) + sizeof(drv_msg.msg_subtype) +
                 sizeof(drv_msg.seq) + sizeof(drv_msg.pl_msg_sz) + drv_msg.pl_msg_sz;
    rlen = read(fd, buf, rlen);
    if(rlen > 0) {
        if(drv_msg.msg_type == SIERRA_KS_IF_DRV_MSG_TYPE_KEY_RSP) {
            if(drv_msg.msg_subtype == SIERRA_KS_IF_DRV_MSG_TYPE_DM_VERITY_KEY_LGT_RSP) {
                printf("%s\n", drv_msg.payload);
            }
        }
    }
    else {
        //printf("Driver returned an error: 0x%lx\n", rlen);
    }

    /* Close the device. */
    close(fd);
}

