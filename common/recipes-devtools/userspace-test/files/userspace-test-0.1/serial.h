/* serial.h
    (C) 2004-5 Captain http://www.captain.at

    Helper functions for "ser"

    Used for testing the PIC-MMC test-board
    http://www.captain.at/electronic-index.php
*/

#include <stdio.h>   /* Standard input/output definitions */
#include <string.h>  /* String function definitions */
#include <unistd.h>  /* UNIX standard function definitions */
#include <fcntl.h>   /* File control definitions */
#include <errno.h>   /* Error number definitions */
#include <termios.h> /* POSIX terminal control definitions */
#include <sys/signal.h>
#include <sys/stat.h>
#include <sys/types.h>

#define TRUE    1
#define FALSE   0

int wait_flag = TRUE;   // TRUE while no signal received

// Definition of Signal Handler
void DAQ_signal_handler_IO ( int status )
{
    //~ fprintf(stdout, "received SIGIO signal %d.\n", status);
    wait_flag = FALSE;
}


int writeport( int fd, char *comm ) 
{
    int len = strlen( comm );
    int n = write( fd, comm, len );

    if ( n < 0 ) 
    {
        fprintf(stdout, "write failed!\n");
        return 0;
    }

    return n;
}


int readport( int fd, char *resp, size_t nbyte ) 
{
    int iIn = read( fd, resp, nbyte );
    if ( iIn < 0 ) 
    {
        if ( errno == EAGAIN ) 
        {
            fprintf(stdout, "SERIAL EAGAIN ERROR\n");
            return 0;
        } 
        else 
        {
            fprintf(stdout, "SERIAL read error: %d = %s\n", errno , strerror(errno));
            return 0;
        }
    }

    if ( resp[iIn-1] == '\r' )
        resp[iIn-1] = '\0';
    else
        resp[iIn] = '\0';

    return iIn;
}


int getbaud( int fd ) 
{
    struct termios termAttr;
    int inputSpeed = -1;
    speed_t baudRate;
    tcgetattr( fd, &termAttr );
    // Get the input speed
    baudRate = cfgetispeed( &termAttr );
    switch ( baudRate )
    {
        case B0:      inputSpeed = 0; break;
        case B50:     inputSpeed = 50; break;
        case B110:    inputSpeed = 110; break;
        case B134:    inputSpeed = 134; break;
        case B150:    inputSpeed = 150; break;
        case B200:    inputSpeed = 200; break;
        case B300:    inputSpeed = 300; break;
        case B600:    inputSpeed = 600; break;
        case B1200:   inputSpeed = 1200; break;
        case B1800:   inputSpeed = 1800; break;
        case B2400:   inputSpeed = 2400; break;
        case B4800:   inputSpeed = 4800; break;
        case B9600:   inputSpeed = 9600; break;
        case B19200:  inputSpeed = 19200; break;
        case B38400:  inputSpeed = 38400; break;
        case B115200: inputSpeed = 115200; break;
        case B2000000: inputSpeed = 2000000; break; //added
		case B2500000: inputSpeed = 2500000; break; //added
		case B3000000: inputSpeed = 3000000; break; //added
		case B3500000: inputSpeed = 3500000; break; //added
		case B4000000: inputSpeed = 4000000; break; //added
    }
    return inputSpeed;
}


/* ser.c
    (C) 2004-5 Captain http://www.captain.at

    Sends 3 characters (ABC) via the serial port (/dev/ttyS0) and reads
    them back if they are returned from the PIC.

    Used for testing the PIC-MMC test-board
    http://www.captain.at/electronic-index.php

*/


int initport( int fd, speed_t baudRate ) 
{
    struct termios options;
    struct sigaction saio;  // Definition of Signal action

    // Install the signal handler before making the device asynchronous
    saio.sa_handler = DAQ_signal_handler_IO;
    saio.sa_flags = 0;
    saio.sa_restorer = NULL;
    sigaction( SIGIO, &saio, NULL );

    // Allow the process to receive SIGIO
    fcntl( fd, F_SETOWN, getpid() );
    // Make the file descriptor asynchronous (the manual page says only 
    // O_APPEND and O_NONBLOCK, will work with F_SETFL...)
    fcntl( fd, F_SETFL, FASYNC );
    //~ fcntl( fd, F_SETFL, FNDELAY); //doesn't work; //fcntl(file, F_SETFL, 0);

    // Get the current options for the port...
    tcgetattr( fd, &options );
/*       
    // Set port settings for canonical input processing
    options.c_cflag = BAUDRATE | CRTSCTS | CLOCAL | CREAD;
    options.c_iflag = IGNPAR | ICRNL;
    //options.c_iflag = IGNPAR;
    options.c_oflag = 0;
    options.c_lflag = ICANON;
    //options.c_lflag = 0;
    options.c_cc[VMIN] = 0;
    options.c_cc[VTIME] = 0;
*/   
    /* ADDED - else 'read' will not return, unless it sees LF '\n' !!!!
    * From: Unix Programming Frequently Asked Questions - 3. Terminal I/O - 
    * http://www.steve.org.uk/Reference/Unix/faq_4.html 
    */
    /* Disable canonical mode, and set buffer size to 1 byte */
    options.c_lflag &= (~ICANON);
    options.c_cc[VTIME] = 0;
    options.c_cc[VMIN] = 1; 

    // Set the baud rates to...
    cfsetispeed( &options, baudRate );
    cfsetospeed( &options, baudRate );

    // Enable the receiver and set local mode...
    options.c_cflag |= ( CLOCAL | CREAD );
    options.c_cflag &= ~PARENB;
    options.c_cflag &= ~CSTOPB;
    options.c_cflag &= ~CSIZE;
    options.c_cflag |= CS8;

    // Flush the input & output...
    tcflush( fd, TCIOFLUSH );

    // Set the new options for the port...
    tcsetattr( fd, TCSANOW, &options );

    return 1;
}


/* 
    ripped from 
    http://git.savannah.gnu.org/cgit/coreutils.git/tree/src/stty.c
*/

#define STREQ(a, b)     (strcmp((a), (b)) == 0)

struct speed_map
{
  const char *string;       /* ASCII representation. */
  speed_t speed;        /* Internal form. */
  unsigned long int value;  /* Numeric value. */
};

static struct speed_map const speeds[] =
{
  {"0", B0, 0},
  {"50", B50, 50},
  {"75", B75, 75},
  {"110", B110, 110},
  {"134", B134, 134},
  {"134.5", B134, 134},
  {"150", B150, 150},
  {"200", B200, 200},
  {"300", B300, 300},
  {"600", B600, 600},
  {"1200", B1200, 1200},
  {"1800", B1800, 1800},
  {"2400", B2400, 2400},
  {"4800", B4800, 4800},
  {"9600", B9600, 9600},
  {"19200", B19200, 19200},
  {"38400", B38400, 38400},
  {"exta", B19200, 19200},
  {"extb", B38400, 38400},
#ifdef B57600
  {"57600", B57600, 57600},
#endif
#ifdef B115200
  {"115200", B115200, 115200},
#endif
#ifdef B230400
  {"230400", B230400, 230400},
#endif
#ifdef B460800
  {"460800", B460800, 460800},
#endif
#ifdef B500000
  {"500000", B500000, 500000},
#endif
#ifdef B576000
  {"576000", B576000, 576000},
#endif
#ifdef B921600
  {"921600", B921600, 921600},
#endif
#ifdef B1000000
  {"1000000", B1000000, 1000000},
#endif
#ifdef B1152000
  {"1152000", B1152000, 1152000},
#endif
#ifdef B1500000
  {"1500000", B1500000, 1500000},
#endif
#ifdef B2000000
  {"2000000", B2000000, 2000000},
#endif
#ifdef B2500000
  {"2500000", B2500000, 2500000},
#endif
#ifdef B3000000
  {"3000000", B3000000, 3000000},
#endif
#ifdef B3500000
  {"3500000", B3500000, 3500000},
#endif
#ifdef B4000000
  {"4000000", B4000000, 4000000},
#endif
  {NULL, 0, 0}
};

static speed_t
string_to_baud (const char *arg)
{
  int i;

  for (i = 0; speeds[i].string != NULL; ++i)
    if (STREQ (arg, speeds[i].string))
      return speeds[i].speed;
  return (speed_t) -1;
}



/* http://www.gnu.org/software/libtool/manual/libc/Elapsed-Time.html
Subtract the `struct timeval' values X and Y,
storing the result in RESULT.
Return 1 if the difference is negative, otherwise 0.  */
int timeval_subtract (struct timeval *result, struct timeval *x, struct timeval *y)
{
    /* Perform the carry for the later subtraction by updating y. */
    if (x->tv_usec < y->tv_usec) {
     int nsec = (y->tv_usec - x->tv_usec) / 1000000 + 1;
     y->tv_usec -= 1000000 * nsec;
     y->tv_sec += nsec;
    }
    if (x->tv_usec - y->tv_usec > 1000000) {
     int nsec = (x->tv_usec - y->tv_usec) / 1000000;
     y->tv_usec += 1000000 * nsec;
     y->tv_sec -= nsec;
    }

    /* Compute the time remaining to wait.
      tv_usec is certainly positive. */
    result->tv_sec = x->tv_sec - y->tv_sec;
    result->tv_usec = x->tv_usec - y->tv_usec;

    /* Return 1 if result is negative. */
    return x->tv_sec < y->tv_sec;
}