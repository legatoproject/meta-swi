/*
********************************************************************************
* Name:  sierra_ks_if_intf.h
*
* Sierra Wireless keystore userland interface file. This file contains
* information required by userland and keystore kernel module only.
*
* License Mozilla Public License Version 2.0
*
*===============================================================================
* Copyright (C) 2019 Sierra Wireless Inc.
********************************************************************************
*/
#ifndef _SIERRA_KS_IF_INTF_H
#define _SIERRA_KS_IF_INTF_H

/* Make sure none is defined. */
#undef TRUE
#undef FALSE

/* Redefine to make sure that we know what it is. */
#define TRUE    (1)
#define FALSE   (0)

#ifndef __KERNEL__
#define PAGE_SIZE   4096
#endif

/* Driver name */
#define SIERRA_KS_IF_DRV_NAME   "sierra_ks_if"

/* Userland interface device. */
#define SIERRA_KS_IF_DEV_NAME   SIERRA_KS_IF_DRV_NAME

/*
 * Sierra keystore message types. The fields may be embedded into msg_type or
 * msg_subtype of the sierra_ks_if_drv_msg .
 * Userland will make the request, and kernel will send response to that
 * request.
 */
typedef enum {

    /* The very beginning */
    SIERRA_KS_IF_DRV_MSG_TYPE_NONE = 0,

    /* Get the key.
     * sierra_ks_if_drv_msg.msg_type = SIERRA_KS_IF_DRV_MSG_TYPE_KEY_*
     * The exact key would be defined in msg_subtype.
     */
    SIERRA_KS_IF_DRV_MSG_TYPE_KEY_REQ,
    SIERRA_KS_IF_DRV_MSG_TYPE_KEY_RSP,

    /* Get rootfs dm-verity key.
     * This is part of msg_subtype field of sierra_ks_if_drv_msg. If this key
     * is requested, you need to have :
     * sierra_ks_if_drv_msg.msg_type = SIERRA_KS_IF_DRV_MSG_TYPE_KEY_*
     * sierra_ks_if_drv_msg.msg_subtype = SIERRA_KS_IF_DRV_MSG_TYPE_DM_VERITY_KEY_*
     */
    SIERRA_KS_IF_DRV_MSG_TYPE_DM_VERITY_KEY_RFS_REQ,
    SIERRA_KS_IF_DRV_MSG_TYPE_DM_VERITY_KEY_RFS_RSP,

    /* Get legato dm-verity key.
     * This is part of msg_subtype field of sierra_ks_if_drv_msg. If this key
     * is requested, you need to have :
     * sierra_ks_if_drv_msg.msg_type = SIERRA_KS_IF_DRV_MSG_TYPE_KEY_*
     * sierra_ks_if_drv_msg.msg_subtype = SIERRA_KS_IF_DRV_MSG_TYPE_DM_VERITY_KEY_*
     */
    SIERRA_KS_IF_DRV_MSG_TYPE_DM_VERITY_KEY_LGT_REQ,
    SIERRA_KS_IF_DRV_MSG_TYPE_DM_VERITY_KEY_LGT_RSP,

    /* Get the driver status.
     * sierra_ks_if_drv_msg.msg_type = SIERRA_KS_IF_DRV_MSG_TYPE_DRV_STATUS_*
     */
    SIERRA_KS_IF_DRV_MSG_TYPE_DRV_STATUS_REQ,
    SIERRA_KS_IF_DRV_MSG_TYPE_DRV_STATUS_RSP,

    /* Driver test 1.
     * sierra_ks_if_drv_msg.msg_type = SIERRA_KS_IF_DRV_MSG_TYPE_TEST1_*
     */
    SIERRA_KS_IF_DRV_MSG_TYPE_TEST1_REQ,            /* Test 1 function. */
    SIERRA_KS_IF_DRV_MSG_TYPE_TEST1_RSP,        /* Test 1 function response. */

    /* Cannot pass this point. */
    SIERRA_KS_IF_DRV_MSG_TYPE_LAST,
} SIERRA_KS_IF_DRV_MSG_TYPE_E;

/* Message structure for information exchange between kernel and userland. */
typedef struct _sierra_ks_if_drv_msg {
    /* message type: SIERRA_KS_IF_DRV_MSG_TYPE_E */
    unsigned char msg_type;

    /* Typically, this is used as a suplement to msg_type entry. */
    unsigned char msg_subtype;

    /* Sequence number. Set to 0, if not used. Note that receiver should just
     * copy this field into its reply to sender.
     */
    unsigned short seq;

    /* Payload message size (in bytes). */
    unsigned short pl_msg_sz;

    /* fixed size payload, no pointers here */
    unsigned char payload[PAGE_SIZE - ( (2 * sizeof(unsigned char)) +
                                        (2 * sizeof(unsigned short)) )];
} sierra_ks_if_drv_msg;

#endif /* _SIERRA_KS_IF_INTF_H */

