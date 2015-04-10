#include <termios.h>
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <getopt.h>

int
main(int argc, char *argv[])
{
  
  int fd, serial, status, lstatus;
  serial = 0; 
  status = 0;
  lstatus = 0;
  static const char *device = "/dev/ttyHSL1";

 fd = open(device, O_RDWR);
  //All in
  status |= TIOCM_LE|TIOCM_DTR|TIOCM_RTS|TIOCM_ST|TIOCM_SR|TIOCM_CTS|TIOCM_CAR|TIOCM_RNG|TIOCM_DSR;
  ioctl(fd, TCSETSF, &status);

  usleep(200);
  
  ioctl(fd, TIOCMGET, &serial);
  printf ("serial is %x \n",serial);
  
  close(fd);
  
fd = open(device, O_RDWR);

    status &= ~TIOCM_DTR;
  ioctl(fd, TIOCMSET, &status);
  usleep(200);
  ioctl(fd, TIOCMGET, &serial);
  printf ("serial is %x \n",serial);
  

  status &= ~TIOCM_RTS;
  ioctl(fd, TIOCMSET, &status);
  usleep(200);
  ioctl(fd, TIOCMGET, &serial);
  printf ("serial is %x \n",serial);

  
  status &= ~TIOCM_ST;
  ioctl(fd, TIOCMSET, &status);
  usleep(200);
  ioctl(fd, TIOCMGET, &serial);
  printf ("serial is %x \n",serial);

  status &= ~TIOCM_SR;
  ioctl(fd, TIOCMSET, &status);
  usleep(200);
  ioctl(fd, TIOCMGET, &serial);
  printf ("serial is %x \n",serial);

  ioctl(fd, TIOCGSOFTCAR, &lstatus);
  printf ("clocal status is  %x \n",lstatus);

  ioctl(fd, TIOCSSOFTCAR, TIOCM_RTS);
  ioctl(fd, TIOCGSOFTCAR, &lstatus);
  printf ("clocal status is  %x \n",lstatus);

  status &= ~TIOCM_RTS;
  ioctl(fd, TIOCMSET, &status);
  usleep(200);
  ioctl(fd, TIOCMGET, &serial);
  printf ("serial is %x \n",serial);
  
  //printf ("clocal status is  %x \n",lstatus);

  close(fd);
}
