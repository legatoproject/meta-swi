/*
    writeread.c - based on writeread.cpp
    [SOLVED] Serial Programming, Write-Read Issue - http://www.linuxquestions.org/questions/programming-9/serial-programming-write-read-issue-822980/

    build with: gcc -o writeread -lpthread -Wall -g writeread.c
*/

#include <stdio.h>
#include <string.h>
#include <stddef.h>

#include <stdlib.h>
#include <sys/time.h>

#include <pthread.h>

#include "serial.h"

int serport_fd;

void usage(char **argv)
{
    fprintf(stdout, "Usage:\n"); 
    fprintf(stdout, "%s port baudrate file/string\n", argv[0]); 
    fprintf(stdout, "Examples:\n"); 
    fprintf(stdout, "%s /dev/ttyUSB0 115200\n", argv[0]); 
}

int main( int argc, char **argv ) 
{

    if( argc != 3 ) { 
        usage(argv);
        return 1; 
    }
	
    char *serport;
    char *serspeed;
    speed_t serspeed_t;
    int readChars;
    int recdBytes; 

    char* sResp;
    char* sRespTotal;

    FILE *stdalt;
    if(dup2(3, 3) == -1) {
        fprintf(stdout, "stdalt not opened; ");
        stdalt = fopen("/dev/tty", "w");
    } else {
        fprintf(stdout, "stdalt opened; ");
        stdalt = fdopen(3, "w");
    }
    fprintf(stdout, "Alternative file descriptor: %d\n", fileno(stdalt));

    // Get the PORT name
    serport = argv[1];
    fprintf(stdout, "Opening port %s;\n", serport);

    // Get the baudrate
    serspeed = argv[2];
    serspeed_t = string_to_baud(serspeed);
    fprintf(stdout, "Got speed %s (%d/0x%x);\n", serspeed, serspeed_t, serspeed_t);
	
	sResp = (char *)calloc(58, sizeof(char));
    sRespTotal = (char *)calloc(58, sizeof(char));

    // Open and Initialise port
    serport_fd = open( serport, O_RDWR | O_NOCTTY | O_NONBLOCK );
    if ( serport_fd < 0 ) { perror(serport); return 1; }
    initport( serport_fd, serspeed_t );
	
	 // run read loop 
    while ( 1 )
    {
        if ( (readChars = read( serport_fd, sResp, 60)) >= 0 ) 
        {
            //~ fprintf(stdout, "InVAL: (%d) %s\n", readChars, sResp);
            // binary safe - add sResp chunk to sRespTotal
            memmove(sRespTotal+recdBytes, sResp+0, readChars*sizeof(char));
            // text safe, but not binary:
            sResp[readChars] = '\0'; 
            fprintf(stdout, "%s", sResp);
       
            recdBytes += readChars;
        } else {
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
        fprintf(stderr, "   read: %d\n", recdBytes);   

        if(recdBytes > 58)	
		{
		    fprintf(stderr, "   read over\n");   
            break;		
        }
    }

    close(serport_fd);
	
    return 0;
}
