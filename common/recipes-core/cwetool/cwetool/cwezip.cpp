/*************
*
* $Id$
*
* Filename:   CWEZIP.CPP
*
* Purpose:    This file compresses a CWE file using zlib
*
* Note:       This file depends on zlib DLL (www.zlib.net)
*
* Copyright:  © 2011 Sierra Wireless
*             All rights reserved
*
**************/

/* Include files */
#include <iostream>
#include <fstream>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>

#include "zconf.h"
#include "zlib.h"

using namespace std;

typedef unsigned char uint8;    /* 8 bit integer unsigned           */
typedef unsigned short uint16;  /* 16 bit integer unsigned           */
typedef unsigned long uint32;   /* 32 bit integer unsigned           */
typedef signed long int32;      /* 32 bit integer signed           */
#define TRUE 1
#define FALSE 0
#ifndef NULL
#define NULL 0
#endif


#define _local static   /* accessed within local file only */
#define _package        /* function accessed within package, not permitted for variables */
#define _global         /* function accessed globally, not permitted for variables */

/* header field offset constants (relative to the first byte of image in flash) */
#define BC_PROD_BUF_OFST      0x000
#define BC_CRC_PROD_BUF_OFST  0x100
#define BC_HDR_REV_NUM_OFST   0x104
#define BC_CRC_INDICATOR_OFST 0x108
#define BC_IMAGE_TYPE_OFST    0x10C
#define BC_PROD_TYPE_OFST     0x110
#define BC_IMAGE_SIZE_OFST    0x114
#define BC_CRC32_OFST         0x118
#define BC_VERSION_OFST       0x11C
#define BC_REL_DATE_OFST      0x170
#define BC_COMPAT_OFST        0x178
#define BC_HDR_MISC_OPTS_OFST 0x17C
#define BC_HDR_RES_OFST       0x17D
#define BC_STOR_ADDR_OFST     0x180
#define BC_PROG_ADDR_OFST     0x184
#define BC_ENTRY_OFST         0x188
#define BC_SIGNATURE_OFST     0x18C
#define BC_HEADER_SIZE        0x190

/* Misc Options Field Bit Map */
#define BC_MISC_OPTS_COMPRESS 0x01  /* image following header is compressed */
#define BC_MISC_OPTS_ENCRYPT  0x02  /* image following header is encrypyted */

static const char toolVersion[] = "1.00" ;


/* Local constants and enumerated types */
#define COMPCHUNKSZ         20000
#define DECOMPCHUNKSZ       2000

uint8 decbuf[DECOMPCHUNKSZ];  /* decpression buffer  - not used */


/* Local structures */

/*************
*
* Name:     lzctl_s - compression control block
*
* Purpose:  Control block for compression
*
* Members:  fpsource       - input file
*           fpdest         - output file
*           compressimages - flag to indicate compress/decompress
*           cweformat      - flag to indicate if the file is in CWE format
*
* Notes:    None
*
**************/
typedef struct
{
  FILE *fpsource;
  FILE *fpdest;
  bool compressimages;
  bool cweformat;
} lzctl_s;




/* Functions */

/*************
*
* Name:     fsizeof - get the size of a file
*
* Purpose:  Gets the size of a file
*
* Parms:    (IN) fp - input file
*
* Return: 	Size of the input file
*
* Abort: 	  None
*
* Notes: 	  Input file is rewound to the start of the file
*
**************/
_local int32 fsizeof(FILE *fp)
{
  int32 len;

  fseek(fp, 0, SEEK_END);
  len = ftell(fp);
  rewind(fp);
  return len;
}

/*************
*
* Name:     putuint32nbo - put uint32 into the CWE header in network byte order
*
* Purpose:  Change the numbers/sizes in CWE header
*
* Parms:    (IN) fp - output file
*           (IN) ver - number
*
* Return: 	None
*
* Abort: 	None
*
* Notes: 	Always write 4 bytes for the version field.
*
**************/
_local void putuint32nbo(FILE *fp, uint32 ver)
{
  uint8 verarray[4];
  uint32 i=0;

  verarray[0] = (uint8) (ver>>24)&0xff;
  verarray[1] = (uint8) (ver>>16)&0xff;
  verarray[2] = (uint8) (ver>>8)&0xff;
  verarray[3] = (uint8) ver&0xff;

  for(i=0; i<4; i++)
  {
    putc(verarray[i], fp);
  }

}

/*
 *  Name:       bccopy - copy CWE header
 *
 *  Purpose:    Copies the CWE header from one file to another
 *
 *  Parameters: (IN) fpsource - input file
 *              (OUT) fpdest  - output file
 *
 *  Returns:    TRUE if header was copied, FALSE if input file was too short
 *
 *  Abort:      None
 *
 *  Notes:      CWE header is not verified for accuracy
 *
 */
_global bool bccopy(FILE* fpsource, FILE* fpdest)
{
  uint32 i;
  uint8 data;

  for (i=0; i<BC_HEADER_SIZE; i++)
  {
    if ( feof(fpsource) ) /* check for end of file */
    {
      printf ("\n**** INVALID FILE - NO HEADER ****\n");
      return FALSE;
    }
    data = fgetc(fpsource);
    putc( data, fpdest );
  }
  return(TRUE);
}

/*************
*
* Name:     compressfile - compress input file
*
* Purpose:  Compress the file
*
* Parms:    (IN) fpuncomp - input file
*           (OUT) fpcomp  - output file
*           (IN) cweformat - whether input file is in CWE format
*
* Return: 	FALSE if the CWE header was not copied correctly, TRUE otherwise
*
* Abort: 	  None
*
* Notes: 	  This is a simplified version of compression/decompression which
*             assumes the entire files can be stored in RAM buffer.
*             To compress/decompress chunk by chunk, please see example.c
*             in zlib source release.
*
**************/
_local bool compressfile(FILE *fpuncomp, FILE *fpcomp, bool cweformat)
{
  uint8* ibufp;
  uint32 ibuflen;
  uint8* obufp;
  uint32 obuflen;
  uint8 data;
  uint32 i;
  uint8* bufp;
  uint32 filesz;
  uint32 version = 3;
  int result;

  /**************************************************************************
  * Initialization
  **************************************************************************/
  rewind(fpuncomp);
  filesz = fsizeof(fpuncomp);

  if(cweformat)
  {
    /* Copy over the CWE header */
    if (bccopy(fpuncomp, fpcomp) == FALSE)
    {
      return(FALSE);
    }

    /* set the file compressed bit */
    fseek(fpuncomp, BC_HDR_MISC_OPTS_OFST, SEEK_SET);
    data = fgetc(fpuncomp);
    data |= BC_MISC_OPTS_COMPRESS;
    fseek(fpcomp, BC_HDR_MISC_OPTS_OFST, SEEK_SET);
    putc( data, fpcomp );

    /* set the file to the end of header data */
    fseek(fpcomp, BC_HEADER_SIZE, SEEK_SET);
    fseek(fpuncomp, BC_HEADER_SIZE, SEEK_SET);
  }

  /* read out the whole file and compress it */
  ibufp = (uint8*)malloc(filesz);
  obufp = (uint8*)malloc(filesz);
  ibuflen = 0;
  bufp = ibufp;

  /* read out from the buffer */
  for (i=0; i<filesz; i++)
  {
    if ( feof(fpuncomp) ) /* check for end of file */
    {
      /* account for the file functions always adding an extra byte at the end */
      ibuflen--;
      break;    /* end of file reached */
    }
    data = fgetc(fpuncomp);
    *bufp++ = data;
    ibuflen++;
  }

  /**************************************************************************
   * Compression
   **************************************************************************/
   obuflen = filesz;
   result = compress(obufp, &obuflen, ibufp, ibuflen);

   if(result != Z_OK)
   {
    printf ("file compression error %d\n", result);
    return FALSE;
   }

  /* now write the compressed chunk to a file */
  for( i=0; i<obuflen; i++ )
  {
    putc( obufp[i], fpcomp );
  }

  if(cweformat)
  {
    /* update image size */
    fseek(fpcomp, BC_IMAGE_SIZE_OFST, SEEK_SET);
    putuint32nbo(fpcomp, obuflen);
    /* update hdr version to 3, firmware only check compression option if ver >= 3 */
    fseek(fpcomp, BC_HDR_REV_NUM_OFST, SEEK_SET);
    putuint32nbo(fpcomp, version);
  }
  return TRUE;
}


/*************
*
* Name:     uncompressfile - uncompress input file
*
* Purpose:  Uncompress the file
*
* Parms:    (IN) fpcomp - input file
*           (OUT) fpuncomp  - output file
*
* Return: 	FALSE if the CWE header was not copied correctly, TRUE otherwise
*
* Abort: 	  None
*
* Notes: 	  This is a simplified version of compression/decompression which
*             assumes the entire files can be stored in RAM buffer.
*             To compress/decompress chunk by chunk, please see example.c
*             in zlib source release.
*
**************/
_local bool uncompressfile(FILE* fpcomp, FILE* fpuncomp, bool cweformat)
{
  uint8 *ibufp;
  uint32 ibuflen;
  uint8* obufp;
  uint32 obuflen;
  uint8 data;
  uint32 i;
  uint8* bufp;
  uint32 filesz;
  uint32 version = 3;
  int result;

  /**************************************************************************
  * Initialization
  **************************************************************************/
  rewind(fpcomp);
  filesz = fsizeof(fpcomp);
  if(cweformat)
  {
    filesz -= BC_HEADER_SIZE;

    /* Copy over the CWE header */
    if (bccopy(fpcomp, fpuncomp) == FALSE)
    {
      return(FALSE);
    }

    /* set the file compressed bit */
    fseek(fpcomp, BC_HDR_MISC_OPTS_OFST, SEEK_SET);
    data = fgetc(fpcomp);
    data &= ~BC_MISC_OPTS_COMPRESS;
    fseek(fpuncomp, BC_HDR_MISC_OPTS_OFST, SEEK_SET);
    putc( data, fpuncomp );

    /* set the file to the end of header data */
    fseek(fpcomp, BC_HEADER_SIZE, SEEK_SET);
    fseek(fpuncomp, BC_HEADER_SIZE, SEEK_SET);
  }

  ibufp = (uint8*)malloc(filesz);
  bufp = ibufp;
  /* copy the input file to the buffer */
  for (i=0; i<filesz; i++)
  {
    if ( feof(fpcomp) ) /* check for end of file */
    {
      /* account for the file functions always adding an extra byte at the end */
      ibuflen--;
      break;    /* end of file reached */
    }
    data = fgetc(fpcomp);
    *bufp++ = data;
    ibuflen++;
  }

  obuflen = 70000000;  /* temporary limit out file size to 70MB */
  obufp = (uint8*)malloc(obuflen);

  /**************************************************************************
   * Compression
   **************************************************************************/
  result = uncompress(obufp, &obuflen, ibufp, ibuflen);

  if(result != Z_OK)
  {
    printf ("file decompression error %d\n", result);
    return FALSE;
  }

  /* now write the compressed chunk to a file */
  for( i=0; i<obuflen; i++ )
  {
    putc( obufp[i], fpuncomp );
  }

  if(cweformat)
  {
    /* update image size */
    fseek(fpuncomp, BC_IMAGE_SIZE_OFST, SEEK_SET);
    putuint32nbo(fpuncomp, obuflen);
    /* update hdr version to 3, firmware only check compression option if ver >= 3 */
    fseek(fpuncomp, BC_HDR_REV_NUM_OFST, SEEK_SET);
    putuint32nbo(fpuncomp, version);
  }
  return(TRUE);
}


/*************
*
* Name:     displayintro - Displays intro screen
*
* Purpose:  Displays title screen to the user
*
* Parms:    None
*
* Return: 	None
*
* Abort: 	  None
*
* Notes: 	  None
*
**************/
_local void displayintro(void)
{
  printf("\n");
  printf("CWE image compression tool, version %s\n", toolVersion);
  printf("Copyright 2011, Sierra Wireless, Inc.\n");
  printf("-------------------------------------");
}


/*************
*
* Name:     processargs - processes runtime arguments
*
* Purpose:  Grabs any arguments. Currently supported arguments are:
*             -o <filename> where filename is the desired output file
*             -d decrypt input file
*             -e encrypt input file
*
* Parms:    argc           - number of arguments
*           (IN) argv      - array of arguments
*           (IN/OUT) bfctl - blowfish control block
*
* Return: 	FALSE if not enough arguments were supplied, TRUE otherwise
*
* Abort: 	  None
*
* Notes: 	  None
*
**************/
_local bool processargs
(
  int argc,
  char *argv[],
  lzctl_s *lzctl
)
{
  uint8 c, options;
  uint32 i;

  if (argc < 2)
  {
    printf("\n");
    printf("Usage: %s filename <options>\n", argv[0]);
    printf("Options:\n");
    printf("         -o : Output File Name\n");
    printf("         -c : Compress images\n");
    printf("         -u : Uncompress a combined image\n");
    printf("         -b : Input image is NOT in CWE format\n");
    printf("\n");
    return(0);
  }
  printf("\n");

  lzctl->compressimages = TRUE;
  lzctl->cweformat = TRUE;

  /* open the file to read from */
  lzctl->fpsource = fopen(argv[1], "rb");
  lzctl->fpdest = NULL;
  if (lzctl->fpsource == NULL)
  {
    printf ("\n**** Error opening Image file ****");
    return(FALSE);
  }

  /* check if there are any options */
  options = argc - 2;
  if (options)
  {
    for (i=0; i<options; i++)
    {
      c  = *++argv[2+i];
      /* options found */
      switch (c)
      {
      case 'o':
        if(++i < options)
        {
          /* next argument is file name not another option */
          lzctl->fpdest = fopen(argv[2+i], "wb");
        }
        break;

      case 'c':
        lzctl->compressimages = TRUE;
        break;

      case 'u':
        lzctl->compressimages = FALSE;
        break;

      case 'b':
        lzctl->cweformat = FALSE;
        break;

      default:
        break;
      }
    }
  }

  /* check if the user requested a file name, otherwise use the default */
  if (lzctl->fpdest == NULL)
  {
    lzctl->fpdest = fopen("output.bin", "wb");
  }

  /* check if the file open was a success */
  if (lzctl->fpdest == NULL)
  {
    printf ("\n**** OUTPUT FILE OPEN ERROR ****");
    return(FALSE);
  }

  return(TRUE);
}


/*************
*
* Name:     main - main entry point
*
* Purpose:  Main entry point
*
* Parms:    argc      - number of arguments
*           (IN) argv - array of arguments
*
* Return:   0 for normal execution, non-zero otherwise
*
* Abort:    None
*
* Notes:    None
*
**************/
_global int main(int argc, char *argv[])
{
  uint32 compsz, comprate;
  lzctl_s lzctl;


  /**************************************************************************
  * Initialization
  **************************************************************************/
  displayintro();

  if (processargs(argc, argv, &lzctl) == FALSE)
  {
    return(-1);
  }

  /**************************************************************************
  * Compression/Decompression
  **************************************************************************/
  if (lzctl.compressimages)
  {
    printf("Compressing %s...\n", argv[1]);
    if (compressfile(lzctl.fpsource, lzctl.fpdest, lzctl.cweformat) == FALSE)
    {
      return(-3);
    }

    /* calculate the compressed file size */
    rewind(lzctl.fpdest);
    rewind(lzctl.fpsource);
    compsz = fsizeof(lzctl.fpdest);
    comprate = compsz * 100 / fsizeof(lzctl.fpsource);
    printf("Compressed size: %lu (%lu%%)\n", compsz, comprate);
  }
  else
  {
    printf("Uncompressing %s...\n", argv[1]);
    if (uncompressfile(lzctl.fpsource, lzctl.fpdest, lzctl.cweformat) == FALSE)
    {
      return(-5);
    }
  }

  /**************************************************************************
  * Cleanup
  **************************************************************************/
  if (lzctl.fpsource)
  {
    fclose(lzctl.fpsource);
  }
  if (lzctl.fpdest)
  {
    fclose(lzctl.fpdest);
  }

  printf("\n");

  return(0);
}
