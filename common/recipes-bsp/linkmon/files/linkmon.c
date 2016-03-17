/**
 * linkmon
 * -----------
 *
 * License Mozilla Public License Version 2.0
 *
 * This simple app prevents the target from sleeping when
 * the a USB connection is established.
 *
 * It relies on the presence of /dev/usb_link, which is implemented
 * in the Linux kernel by patch:
 * "msm_otg: Added epoll interface for EPOLLWAKEUP"
 *
 * Author: Zoran Markovic <zmarkovic@sierrawireless.com>
 */

#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/epoll.h>
#include <signal.h>
#include <errno.h>
#include <string.h>

#define WLOCK_FILE "/sys/power/wake_lock"
#define WUNLOCK_FILE "/sys/power/wake_unlock"
#define EPOLL_DEV "/dev/usb_link"
#define MAX_EPOLL 1

static int wake_lock_unlock(int link_status, char *wake_lock)
{
    int wf, rv;

    /* select sysfs file based on current link status */
    wf = open((link_status ? WLOCK_FILE : WUNLOCK_FILE), O_RDWR);
    if (wf < 0) {
        perror("open");
        return -1;
    }
    rv = write(wf, wake_lock, strlen(wake_lock));
    if (rv < 0)
        perror("write");
    close(wf);

    return (rv < 0 ? -1 : 0);
}

int main(int argc, char *argv[])
{
    int fd, epoll_fd, wf;
    FILE *rs;
    struct epoll_event ev, events[MAX_EPOLL];
    char *epoll_dev = EPOLL_DEV;

    if (argc > 1)
        epoll_dev = argv[1];

    /* start by assuming link is up, acquire wake lock */
    if (wake_lock_unlock(1, epoll_dev) < 0)
        exit(EXIT_FAILURE);

    /* create epoll event */
    fd = open(epoll_dev, O_RDONLY);
    if (fd < 0) {
        perror("open");
        exit(EXIT_FAILURE);
    }

    epoll_fd = epoll_create(MAX_EPOLL);
    if (epoll_fd == -1) {
        perror("epoll_create");
        exit(EXIT_FAILURE);
    }
    ev.events = EPOLLWAKEUP | EPOLLIN;
    ev.data.fd = fd;
    if (epoll_ctl(epoll_fd, EPOLL_CTL_ADD, fd, &ev) == -1) {
        perror("epoll_ctl");
        exit(EXIT_FAILURE);
    }

    while (1) {
        int nevents, rv, link_status;

        /* read initial link status */
        rv = read(fd, &link_status, sizeof(link_status));
        if (rv != sizeof(link_status)) {
            perror("read");
            exit(EXIT_FAILURE);
        }
        printf("%s: link is %s\n", epoll_dev,
            (link_status ? "UP" : "DOWN"));

        if (wake_lock_unlock(link_status, epoll_dev) < 0)
            exit(EXIT_FAILURE);

        printf("waiting for EPOLLWAKEUP...\n");
        nevents = 0;
        while (nevents <= 0) {
            /* there's no timeout really, but can add easily */
            nevents = epoll_wait(epoll_fd, events, MAX_EPOLL, -1);
            if (nevents == -1) {
                perror("epoll_wait");
                if (errno != EINTR)
                    exit(EXIT_FAILURE);
            } else if (nevents == 0) {
                printf("epoll_wait timeout.\n");
            }
            /* else epoll event occurred */
        }
    }
    exit(EXIT_SUCCESS);
}
