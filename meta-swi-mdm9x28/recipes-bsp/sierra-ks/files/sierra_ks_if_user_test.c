/*
********************************************************************************
* Name:  sierra_ks_if_user_test.c
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
static void display_help(void);
static void test1(void);
static void test2(void);
static void test3(void);
static void test4(void);

int main (int argc, char **argv)
{
    int ret_ok = 0;
    int ret_err = 1;
    int ret = ret_ok;

    /* For option parsing. */
    extern char *optarg;

    this_e = argv[0];

    if(argc == 1) { display_help(); return 0; }

    while(1) {

        extern char *optarg;
        extern int optind, opterr, optopt;
        int c;
        int option_index = 0;
        static struct option long_options[] = {
            {"help", 0, NULL, 'h'},
            {"test1", 0, NULL, '1'},
            {"test2", 0, NULL, '2'},
            {"test3", 0, NULL, '3'},
            {"test4", 0, NULL, '4'},
            {NULL,0,NULL,0}, /* Must be terminated because it segfaults on
                                incorrect entry. */
        };

        /* Get some long options */
        c = getopt_long(argc, argv, "h1234", &long_options[0], &option_index);

        /* Exit while loop on error. */
        if(c == (-1)) {
            break;
        }

        /* Lets see what we can do about the opptions passed to us. */
        switch(c) {

            case 0:
            {
                printf("Nothing to do for option 0.\n");
            }
            break;

            case '1':
            {
                printf("Running test1...\n");
                test1();
            }
            break;

            case '2':
            {
                printf("Running test2...\n");
                test2();
            }
            break;

            case '3':
            {
                printf("Running test3...\n");
                test3();
            }
            break;

            case '4':
            {
                printf("Running test4...\n");
                test4();
            }
            break;

            case 'h':
            {
                display_help();
            }
            break;

            default:
            {
                printf("Breaking on default\n");
            }
            break;
        }
    }

    return ret;
}

void display_help(void)
{
    printf("\n"
           "sierra_ks_if_user_test version %s\n"
           "Copyright (c) 2019 Sierra Wireless Inc.\n"
           "Dragan Marinkovic <dmarinkovi@sierrawireless.com>\n"
           "\n"
           "Usage: %s <operation> <operation_options>\n"
           "Tests Sierra keystore driver operations, where operations and its parameters are: \n"
           "    Run test 1         : --test1 (send simple message to driver)\n"
           "    Run test 2         : --test2 (request RFS dm-verity key)\n"
           "    Run test 3         : --test3 (request Legato dm-verity key)\n"
           "    Run test 4         : --test4 (send invalid message)\n",
           VERSION, this_e);
    printf("\nInfo: System ticks per second is set to %d.\n", sysconf(_SC_CLK_TCK));
    exit(0);
}

/* Send simple test message to the driver, and receive the response. Results
   could be confirmed visually.
*/
void test1(void)
{
    int ret = 0;
    int fd = -1;
    ssize_t rlen;
    sierra_ks_if_drv_msg drv_msg;
    char *buf = (unsigned char *)(&drv_msg);
    char msg[] = "Message from userland to driver.";

    /* Open keystore device. */
    fd = open(system_device, O_RDWR | O_SYNC);
    if( fd == -1) {
        printf("(%s): Can't open '%s'.\n", __FUNCTION__, system_device);
        return;
    }

    /* Initialize driver storage. */
    memset((void*)(&drv_msg), 0, sizeof(drv_msg));

    /* We will play the tricks here and send the message to driver using read. */
    drv_msg.msg_type = SIERRA_KS_IF_DRV_MSG_TYPE_TEST1_REQ;
    drv_msg.msg_subtype = SIERRA_KS_IF_DRV_MSG_TYPE_NONE;
    drv_msg.seq = 0;
    strcpy(drv_msg.payload, msg);
    /* Tell the driver what's the size of the message we are sending. */
    drv_msg.pl_msg_sz = strlen(drv_msg.payload);

    /* Total size of the message we are sending via read. */
    rlen = sizeof(drv_msg.msg_type) + sizeof(drv_msg.msg_subtype) +
                 sizeof(drv_msg.seq) + sizeof(drv_msg.pl_msg_sz) + drv_msg.pl_msg_sz;
    rlen = read(fd, buf, rlen);
    if(rlen > 0) {
        printf("Driver returned %ld bytes.\n", rlen);
        if(drv_msg.msg_type == SIERRA_KS_IF_DRV_MSG_TYPE_TEST1_RSP) {
            printf("Message from driver: [%s]\n", drv_msg.payload);
        }
    }
    else {
        printf("Driver returned an error: 0x%lx\n", rlen);
    }

    /* Close the device. */
    close(fd);
}

/* Request RFS dm-verity key from the kernel. */
void test2(void)
{
    int ret = 0;
    int fd = -1;
    ssize_t rlen;
    sierra_ks_if_drv_msg drv_msg;
    char *buf = (unsigned char *)(&drv_msg);

    /* Open keystore device. */
    fd = open(system_device, O_RDWR | O_SYNC);
    if( fd == -1) {
        printf("(%s): Can't open '%s'.\n", __FUNCTION__, system_device);
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
        printf("Driver returned %ld bytes.\n", rlen);
        if(drv_msg.msg_type == SIERRA_KS_IF_DRV_MSG_TYPE_KEY_RSP) {
            printf("Received the key from kernel.\n");
            if(drv_msg.msg_subtype == SIERRA_KS_IF_DRV_MSG_TYPE_DM_VERITY_KEY_RFS_RSP) {
                printf("Received dm-verity RFS key from kernel: [%s]\n", drv_msg.payload);
            }
        }
    }
    else {
        printf("Driver returned an error: 0x%lx\n", rlen);
    }

    /* Close the device. */
    close(fd);
}

/* Request Legato dm-verity key from the kernel. */
void test3(void)
{
    int ret = 0;
    int fd = -1;
    ssize_t rlen;
    sierra_ks_if_drv_msg drv_msg;
    char *buf = (unsigned char *)(&drv_msg);

    /* Open keystore device. */
    fd = open(system_device, O_RDWR | O_SYNC);
    if( fd == -1) {
        printf("(%s): Can't open '%s'.\n", __FUNCTION__, system_device);
        return;
    }

    /* Initialize driver storage. */
    memset((void*)(&drv_msg), 0, sizeof(drv_msg));

    /* We will play the tricks here and send the message to driver using read. */
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
        printf("Driver returned %ld bytes.\n", rlen);
        if(drv_msg.msg_type == SIERRA_KS_IF_DRV_MSG_TYPE_KEY_RSP) {
            printf("Received the key from kernel.\n");
            if(drv_msg.msg_subtype == SIERRA_KS_IF_DRV_MSG_TYPE_DM_VERITY_KEY_LGT_RSP) {
                printf("Received dm-verity LGT key from kernel: [%s]\n", drv_msg.payload);
            }
        }
    }
    else {
        printf("Driver returned an error: 0x%lx\n", rlen);
    }

    /* Close the device. */
    close(fd);
}

/* Send invalid request to the kernel. */
void test4(void)
{
    int ret = 0;
    int fd = -1;
    ssize_t rlen;
    sierra_ks_if_drv_msg drv_msg;
    char *buf = (unsigned char *)(&drv_msg);

    /* Open keystore device. */
    fd = open(system_device, O_RDWR | O_SYNC);
    if( fd == -1) {
        printf("(%s): Can't open '%s'.\n", __FUNCTION__, system_device);
        return;
    }

    /* Initialize driver storage. */
    memset((void*)(&drv_msg), 0, sizeof(drv_msg));

    /* We will play the tricks here and send the message to driver using read. */
    drv_msg.msg_type = SIERRA_KS_IF_DRV_MSG_TYPE_LAST;
    drv_msg.msg_subtype = SIERRA_KS_IF_DRV_MSG_TYPE_NONE;
    drv_msg.seq = 0;

    /* Tell the driver what's the size of the message we are sending. */
    drv_msg.pl_msg_sz = 0;

    /* Total size of the message we are sending via read. */
    rlen = sizeof(drv_msg.msg_type) + sizeof(drv_msg.msg_subtype) +
                 sizeof(drv_msg.seq) + sizeof(drv_msg.pl_msg_sz) + drv_msg.pl_msg_sz;
    rlen = read(fd, buf, rlen);
    if(rlen > 0) {
        printf("Driver returned %ld bytes.\n", rlen);
    }
    else {
        printf("Driver returned an error: 0x%lx\n", rlen);
    }

    /* Close the device. */
    close(fd);
}

