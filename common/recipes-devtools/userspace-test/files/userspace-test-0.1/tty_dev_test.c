#include <termios.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <getopt.h>

int
main(int argc, char *argv[])
{
  int fd, serial, status;
  static const char *device = "/dev/ttyHSL1";
  //device = optarg;

  fd = open(device, O_RDONLY);
  ioctl(fd, TIOCMGET, &status);
  printf("status is %d \n",status);
  close(fd);


  fd = open(device, O_RDWR);
    
 if (ioctl(fd, TIOCMSET, TIOCM_LE & status) < 0) {
    printf("Failed to set TIOCM_LE \n");
    
 }

  if (ioctl(fd, TIOCMSET, TIOCM_RI) < 0) {
    printf("Failed to set TIOCM_RI \n");
 }


  if (ioctl(fd, TIOCMSET, TIOCM_CAR) < 0) {
    printf("Failed to set TIOCM_CAR \n");
 }

  if (ioctl(fd, TIOCMSET, TIOCM_CTS) < 0) {
    printf("Failed to set TIOCM_CTS \n");
 }

  close(fd);

    //msm_hs_get_mctrl_locked (device);
    
    fd = open(device, O_RDONLY);

    ioctl(fd, TIOCMGET, &serial);
    if (serial & TIOCM_DTR)
        puts("TIOCM_DTR is not set");
    else
        puts("TIOCM_DTR is set");

    if (serial & TIOCM_LE)
        puts("TIOCM_LE is not set");
    else
        puts("TIOCM_LE is set");
    
    if (serial & TIOCM_CTS)
        puts("TIOCM_CST is not set");
    else
        puts("TIOCM_CST is set");
    
    if (serial & TIOCM_CAR)
        puts("TIOCM_CAR is not set");
    else
        puts("TIOCM_CAR is set");
    
    if (serial & TIOCM_RTS)
        puts("TIOCM_RTS is not set");
    else
        puts("TIOCM_RTS is set");
    
    if (serial & TIOCM_ST)
        puts("TIOCM_ST is not set");
    else
        puts("TIOCM_ST is set");

    if (serial & TIOCM_SR)
        puts("TIOCM_SR is not set");
    else
        puts("TIOCM_SR is set");

    if (serial & TIOCM_RI)
        puts("TIOCM_RI is not set");
    else
        puts("TIOCM_RI is set");


    close(fd);
}
