/*************
*
* $Id$
*
* Filename:   splitboot.c
*
* Purpose:    Extract partition.mbn binary from a CWE
*
* Copyright:  © 2015 Sierra Wireless
*             All rights reserved
*
**************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <fcntl.h>

int main( int argc, char **argv )
{
  int fd, sz;
  int fdo, szo, offo;
  unsigned char hdr[0x190], *buf, vers[85], *p;

  if( argc < 2 )
  {
    fprintf( stderr, "Missing argument\n" );
    exit( 1 );
  }
  if( 0 > (fd = open( argv[1], O_RDONLY )) )
  {
    fprintf( stderr, "Unable to open file: %m\n" );
    exit( 1 );
  }
  if( sizeof( hdr ) != read( fd, hdr, sizeof( hdr ) ) )
  {
    fprintf( stderr, "Read failed: %m\n" );
    close( fd );
    exit( 1 );
  }
  if( *(unsigned int *)(&hdr[0x10C]) != 0x544F4F42 )
  {
    fprintf( stderr, "File corrupted\n" );
    close( fd );
    exit( 1 );
  }
  memcpy( vers, &hdr[0x11C], sizeof(vers)-1 );
  vers[sizeof(vers)-1] = 0;
  p = strtok( vers, " " );
  if( p )
  {
    if( 0 > (fdo = open( "firmware_version.txt", O_WRONLY | O_TRUNC | O_CREAT, 0644 )) )
    {
      fprintf( stderr, "Unable to open file: %m\n" );
      free( buf );
      close( fd );
      exit( 1 );
    }
    write( fdo, vers, strlen(vers) );
    close( fdo );
  }
  sz = *(int *)(&hdr[0x114]);
  sz = ((sz >> 24) & 0xFF) |
       (((sz >> 16) & 0xFF) << 8) |
       (((sz >> 8) & 0xFF) << 16) |
       (((sz >> 0) & 0xFF) << 24);
  if( NULL == (buf = (unsigned char *)malloc( sz )) )
  {
    fprintf( stderr, "Failed to allocate\n" );
    close( fd );
    exit( 1 );
  }
  if( sz != read( fd, buf, sz ) )
  {
    fprintf( stderr, "Read failed: %m\n" );
    close( fd );
    exit( 1 );
  }
  if( *(unsigned int *)(&buf[0x10C]) != 0x52415051 )
  {
    fprintf( stderr, "File corrupted\n" );
    close( fd );
    free( buf );
    exit( 1 );
  }
  szo = *(int *)(&buf[0x114]);
  szo = ((szo >> 24) & 0xFF) |
       (((szo >> 16) & 0xFF) << 8) |
       (((szo >> 8) & 0xFF) << 16) |
       (((szo >> 0) & 0xFF) << 24);
  if( 0 > (fdo = open( "partition.mbn", O_WRONLY | O_TRUNC | O_CREAT, 0644 )) )
  {
    fprintf( stderr, "Unable to open file: %m\n" );
    free( buf );
    close( fd );
    exit( 1 );
  }
  write( fdo, &buf[400], szo );
  close( fdo );
  szo = sz - (offo = (szo + 400));
  if( 0 > (fdo = open( "all.mbn", O_WRONLY | O_TRUNC | O_CREAT, 0644 )) )
  {
    fprintf( stderr, "Unable to open file: %m\n" );
    free( buf );
    close( fd );
    exit( 1 );
  }
  write( fdo, &buf[offo], szo );
  close( fdo );
  close( fd );
  free( buf );
  exit( 0 );
}
