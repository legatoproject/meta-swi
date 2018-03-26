/*====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*
 
  $Id: $
  
  GENERAL DESCRIPTION
  This tool will be used to generate package header for FOTA images.

    
  EXTERNALIZED FUNCTIONS
 
 
  Copyright (C) 2010 Sierra Wireless Inc., All rights reserved.
  ====*====*====*====*====*====*====*====*====*====*====*====*====*====*====*/

#include <iostream>
#include <fstream>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#include <sys/stat.h>

using namespace std;

static const char toolVersion[] = "1.11" ;


/* defines should conform to bcheader.h */
#define PACKAGE_DESC_SIZE               0x20
#define PACKAGE_CNT_MAX                 8
#define PACKAGE_VER_OFFSET              0x00
#define PACKAGE_IMG_TYPE_OFFSET         0x01
#define PACKAGE_EXT_FLAG_OFFSET			0x02
#define PACKAGE_IMG_OFST_OFFSET         0x04
#define PACKAGE_IMG_SIZE_OFFSET         0x08
#define PACKAGE_IMG_VER_OFFSET          0x0C

#define PACKAGE_HEADER_SIZE             PACKAGE_DESC_SIZE * PACKAGE_CNT_MAX
#define PACKAGE_HEADER_SIZE_EXT_MAX     1536
/* max possible package desc count, -2 for head room, two NULL descriptors at the end */
#define PACKAGE_CNT_MAX_EXT             ((PACKAGE_HEADER_SIZE_EXT_MAX / PACKAGE_DESC_SIZE) - 2)
 
#define PACKAGE_IMG_TYPE_REVERSE_BM     0x80
#define PACKAGE_IMG_TYPE_BOOT_CWE       0x01
#define PACKAGE_IMG_TYPE_PROD_CWE       0x02
#define PACKAGE_IMG_TYPE_GEN_CWE        0x03
#define PACKAGE_IMG_TYPE_AMSS_DIFF      0x08
#define PACKAGE_IMG_TYPE_DSP1_DIFF      0x09
#define PACKAGE_IMG_TYPE_DSP2_DIFF      0x0A
#define PACKAGE_IMG_TYPE_HDAT_DIFF      0x0B
#define PACKAGE_IMG_TYPE_SWOC_DIFF      0x0C
#define PACKAGE_IMG_TYPE_APPS_DIFF      0x0D
#define PACKAGE_IMG_TYPE_SYST_DIFF      0x0E
#define PACKAGE_IMG_TYPE_USER_DIFF      0x0F
#define PACKAGE_IMG_TYPE_DSP3_DIFF      0x10

#define PACKAGE_VER_CURRENT             0x01

#define PACKAGE_FLAG_EXT                0x01
#define PACKAGE_FLAG_RESET              0x02

#define VERSION_SIZE                    84
#define SHORTVER_SIZE                   16
#define CWE_HEADER_SIZE                 0x190


/*
 * provide strncpy for unsigned char as destination, to get rid of warnings
 */
static char * strncpy( unsigned char *dst, const char * src, size_t cnt )
{
  return strncpy( (char *)dst, src, cnt );
}

//----------------------------------------------------------------------------

bool
FileExist(char *file)
{
  bool result;
  ifstream inFile( file, ios::binary | ios::in ) ;
  result =  inFile.is_open();
  if(result)
  {
    inFile.close();
  }
  return result;
}


//----------------------------------------------------------------------------


unsigned long
StrToULongHex(char *str)
{
  unsigned long   res ;
  int             i ;

  res = 0 ;
  i = 0 ;

  while (str[i] != '\0')
  {
    if ((str[i] >= '0') && (str[i] <= '9'))
    {
      res = (res * 16) + str[i] - '0' ;
      i++ ;
    }
    else if ((str[i] >= 'a') && (str[i] <= 'f'))
    {
      res = (res * 16) + (str[i] - 'a') + 10 ;
      i++ ;
    }
    else if ((str[i] >= 'A') && (str[i] <= 'F'))
    {
      res = (res * 16) + (str[i] - 'A') + 10 ;
      i++ ;
    }
    else
    {
      return 0 ;
    }
  }
  return res ;
}


//----------------------------------------------------------------------------


char *
UpperCase(char *str)
{
  for (unsigned int i = 0 ; i < strlen(str) ; i++)
  {
    str[i] = toupper(str[i]) ;
  }
  return str;
}



//----------------------------------------------------------------------------

/*
 * Name:  writeuint32nbo - write uint32 in network byte order
 *
 * Purpose: Convert an unsiged int field (32 bits) into network byte order, no matter
 *      this field is represented in Little or Big Endian
 *
 * Params:  value - value of the 32-bit field
 *      bufp - pointer to the buffer where the result is to be put to
 *
 * Return:  
 *        
 * Note:   
 *
 */

void writeuint32nbo(unsigned int value, unsigned char *bufp)
{
  *bufp = (value >> 24);
  bufp++;
  *bufp = (value >> 16);
  bufp++;
  *bufp = (value >> 8);
  bufp++;
  *bufp = value;
}

/*
 * Name:  readuint32nbo - read uint32 in network byte order
 *
 * Purpose: read an unsiged int field (32 bits) of network byte order
 *
 * Params:  value - value of the 32-bit field
 *      bufp - pointer to the buffer where the result is to be put to
 *
 * Return:  
 *        
 * Note:   
 *
 */

unsigned int readuint32nbo(unsigned char *bufp)
{
  unsigned int value;
  value = (*bufp) << 24;
  bufp++;
  value += (*bufp) << 16;
  bufp++;
  value += (*bufp) << 8;
  bufp++;
  value += (*bufp);
  return value;
}

//----------------------------------------------------------------------------

/*
 * Name:  writeuint32le - write uint32 in little endian order
 *
 * Purpose: Convert an unsiged int field (32 bits) into little endian byte order
 *
 * Params:  value - value of the 32-bit field
 *      bufp - pointer to the buffer where the result is to be put to
 *
 * Return:  
 *        
 * Note:   
 *
 */

void writeuint32le(unsigned int value, unsigned char *bufp)
{
  *bufp = value;
  bufp++;
  *bufp = (value >> 8);
  bufp++;
  *bufp = (value >> 16);
  bufp++;
  *bufp = (value >> 24);
}

/*
 * Name:  convertshortver
 *
 * Purpose: convert long Sierra version date string to short version
 *
 * Params:  verp - normal Sierra version string as input
 *          shortverp - short version string output
 *
 * Return:  
 *        
 * Note:   convert SWI9600M_00.01.00.04 to M0010004 or (NO TAG) 
 *         old format Sierra version string Twxyyzzp is not supported
 */
void convertshortver(char *verp, char *shortverp)
{
  unsigned int    index = 0;
  
  if(!strncmp(verp, "SWI", 3) || !strncmp(verp, "NTG", 3))
  {
    shortverp[0] = verp[7];
    shortverp[1] = verp[10];
    shortverp[2] = verp[12];
    shortverp[3] = verp[13];
    shortverp[4] = verp[15];
    shortverp[5] = verp[16];
    shortverp[6] = verp[18];
    shortverp[7] = verp[19];
  }
  else
  {
    /* (NO TAG) R517 CARDM... , just keep (NO TAG), break at space */
    while(verp[index] && index < SHORTVER_SIZE)
	{
      if(index > 3 && verp[index] == ' ')
	  {
	    break;
	  }
	  shortverp[index] = verp[index];
      index ++;
	}
  }
}

int main(int argc, char *argv[])
{
  ifstream        inHdrFile ; //-- Input package header file
  ofstream        outHdrFile ; //-- Output package header file
  unsigned char   bufferPsb[PACKAGE_HEADER_SIZE_EXT_MAX]  = {0};
  unsigned char   img_type;
  unsigned int    img_offset;
  unsigned int    img_size;
  unsigned int    index, jdex, diff;
  int             nbArg ;
  char            outputHdrFileName[256] ;
  char            extoutputHdrFileName[256] ;
  char            imgtypestr[10]   = {0};
  char            gentypestr[10]   = {0};
  char            directionstr[10] = {0};
  char            verstr[VERSION_SIZE + 1]  = {0};
  char            shortverstr[32]  = {0};
  bool            outputHdrFile = false ;
  bool            imageType = false ;
  bool            genType = false ;
  bool            dirType = false ;
  bool            versionTime = false ;
  bool            result;
  bool            reverse_mode = false;
  bool            need_reset = false;
  struct stat     fstat;

  if (argc < 2)
  {
    cout << endl << endl ;
    cout << "FOTA package header generator, version " << toolVersion << endl ;
    cout << "Copyright (C) 2011 Sierra Wireless, Inc." << endl << endl ;
    cout << "Source code at $Source: $" << endl << endl ;
    cout << "-----------------------------------------" << endl ;
    cout << "USAGE:" << endl ;
    cout << "   fotapkghdrcat <input image file>" << endl ; 
    cout << "          -OH  output package header file  " << endl ; 
    cout << "          -IT  Image Type                  " << endl ;
    cout << "               (OSBL/FSBL/BOOT/APPL/AMSS/DSP1/DSP2/GNRC(Generic)/HDATA/SWOC/DSP3 or a hex value)" << endl ;
    cout << "          -GT  Generator Type (DIFF/FULL)  " << endl ;
    cout << "          -V   Version                     " << endl ;
    cout << "          -D   Direction (FWD/RVS)         " << endl ;
    cout << "          -R   Need reset (YES/NO)         " << endl ;
   cout << endl ;
    return -1 ;
  }

  //-- Make sure the application image file exist
  if (FileExist(argv[1]) != true)
  {
    cout << endl << "ERROR: Application file " << argv[1] << " does not exist" << endl ;
    return 0 ;
  }

  //-- Process the options
  if ((argc > 2) && ((argc - 2) % 2) == 0)
  {
    nbArg = 2 ;
    result = true ;
    while ((nbArg < argc) && (result == true))
    {
      if (strcmp(UpperCase(argv[nbArg]), "-OH") == 0)        //-- Output CWE Header File
      {
        if (outputHdrFile == true)
        {
          //-- Already found argument
          cout << endl << "Output CWE Header File Already Specified" << endl ;
          result = false ;
        }
        else
        {
          outputHdrFile = true ;
          strncpy(outputHdrFileName, argv[nbArg + 1], sizeof(outputHdrFileName)) ;
        }
      }
      else if (strcmp(UpperCase(argv[nbArg]), "-IT") == 0)        //-- Image Type
      {
        if (imageType == true)
        {
          //-- Already found argument
          cout << endl << "Image Type already found" << endl ;
          result = false ;
        }
        else
        {
          imageType = true ;
          if (strlen(argv[nbArg + 1]) > 4)
          {
            cout << endl << "Incorrect Image Type: " 
                 << UpperCase(argv[nbArg + 1]) << endl ;
            result = false ;
          }
          else
          {
            strcpy(imgtypestr, UpperCase(argv[nbArg + 1])) ;
          }
        }
      }
      else if (strcmp(UpperCase(argv[nbArg]), "-GT") == 0)        //-- Generator Type
      {
        if (genType == true)
        {
          //-- Already found argument
          cout << endl << "Generator Type already found" << endl ;
          result = false ;
        }
        else
        {
          genType = true ;
          if (strlen(argv[nbArg + 1]) > 4)
          {
            cout << endl << "Incorrect Generator Type: " 
                 << UpperCase(argv[nbArg + 1]) << endl ;
            result = false ;
          }
          else
          {
            strcpy(gentypestr, UpperCase(argv[nbArg + 1])) ;
          }
        }
      }
      else if (strcmp(UpperCase(argv[nbArg]), "-D") == 0)        //-- Direction Type
      {
        if (dirType == true)
        {
          //-- Already found argument
          cout << endl << "Direction already found" << endl ;
          result = false ;
        }
        else
        {
          dirType = true ;
          if (strlen(argv[nbArg + 1]) > 4)
          {
            cout << endl << "Incorrect Generator Type: " 
                 << UpperCase(argv[nbArg + 1]) << endl ;
            result = false ;
          }
          else
          {
            strcpy(directionstr, UpperCase(argv[nbArg + 1])) ;
          }
        }
      }
      else if (strcmp(UpperCase(argv[nbArg]), "-V") == 0)    //-- Version/Time
      {
        if (versionTime == true)
        {
          //-- Already found argument
          cout << endl << "Version/Time already found" << endl ;
          result = false ;
        }
        else
        {
          versionTime = true ;
          memset(verstr, 0, sizeof(verstr)) ;
          if (strlen(argv[nbArg + 1]) >= VERSION_SIZE)
          {
            strncpy(verstr, UpperCase(argv[nbArg + 1]), VERSION_SIZE) ;
            verstr[VERSION_SIZE] = '\0' ;
          }
          else
          {
            strncpy(verstr, UpperCase(argv[nbArg + 1]), VERSION_SIZE) ;
          }
        }
      }
      else if (strcmp(UpperCase(argv[nbArg]), "-R") == 0)        //-- Need reset or not
      {
        if (strcmp(UpperCase(argv[nbArg + 1]), "YES") == 0)
        {
          need_reset = true;
        }
      }
      nbArg += 2 ;
    }
  }
  if (result == false)
  {
    cout << endl ;
    cout << "There was an ERROR" << endl << endl ;
    return 0 ;
  }

  //-- If the output header file name was not specified, use the input image file name
  if (outputHdrFile == false)
  {
    strncpy(outputHdrFileName, argv[1], sizeof(outputHdrFileName) );
    strcat(outputHdrFileName, ".hdr") ;
  }

  inHdrFile.open(outputHdrFileName, ios::binary | ios::in) ;
  if (inHdrFile.is_open() )
  {
    inHdrFile.read((char *)bufferPsb, PACKAGE_HEADER_SIZE);
    inHdrFile.close() ;
  }

  strcpy(extoutputHdrFileName, outputHdrFileName);
  strcat(extoutputHdrFileName, ".ext") ;
  inHdrFile.open(extoutputHdrFileName, ios::binary | ios::in) ;
  if (inHdrFile.is_open() )
  {
    inHdrFile.read((char *)bufferPsb + PACKAGE_HEADER_SIZE, PACKAGE_HEADER_SIZE_EXT_MAX - PACKAGE_HEADER_SIZE);
    inHdrFile.close() ;
  }

  /* set package info - default values */
  img_type = PACKAGE_IMG_TYPE_PROD_CWE;
  img_offset = CWE_HEADER_SIZE;

  /* get image file size */
  if(stat(argv[1], &fstat) != 0)
  {
    cout << "Could not stat image file " << argv[1] << endl ;
    return 0 ;
  }
  img_size = fstat.st_size;

//  cout << "imageType " << imageType << "imgtypestr " << imgtypestr << endl ;
//  cout << "genType " << genType << "gentypestr " << gentypestr << endl ;
//  cout << "dirType " << dirType << "directionstr " << directionstr << endl ;


  /* image type based on inputs */
  if(imageType && !strncmp(imgtypestr, "0X", 2))
  {
    img_type = StrToULongHex(gentypestr + 2);
  }
  else if(imageType && genType)
  {
    if(!strcmp(imgtypestr, "BOOT") && !strcmp(gentypestr, "FULL"))
    {
      img_type = PACKAGE_IMG_TYPE_BOOT_CWE;
    }
    else if(!strcmp(imgtypestr, "GNRC") && !strcmp(gentypestr, "FULL"))
    {
      img_type = PACKAGE_IMG_TYPE_GEN_CWE;
    }
    else if(!strcmp(gentypestr, "FULL"))
    {
      img_type = PACKAGE_IMG_TYPE_PROD_CWE;
    }
    else if(!strcmp(imgtypestr, "AMSS") && !strcmp(gentypestr, "DIFF"))
    {
      img_type = PACKAGE_IMG_TYPE_AMSS_DIFF;
    }
    else if(!strcmp(imgtypestr, "DSP1") && !strcmp(gentypestr, "DIFF"))
    {
      img_type = PACKAGE_IMG_TYPE_DSP1_DIFF;
    }
    else if(!strcmp(imgtypestr, "DSP2") && !strcmp(gentypestr, "DIFF"))
    {
      img_type = PACKAGE_IMG_TYPE_DSP2_DIFF;
    }
    else if(!strcmp(imgtypestr, "HDAT") && !strcmp(gentypestr, "DIFF"))
    {
      img_type = PACKAGE_IMG_TYPE_HDAT_DIFF;
    }
    else if(!strcmp(imgtypestr, "SWOC") && !strcmp(gentypestr, "DIFF"))
    {
      img_type = PACKAGE_IMG_TYPE_SWOC_DIFF;
    }
    else if(!strcmp(imgtypestr, "APPS") && !strcmp(gentypestr, "DIFF"))
    {
      img_type = PACKAGE_IMG_TYPE_APPS_DIFF;
    }
    else if(!strcmp(imgtypestr, "SYST") && !strcmp(gentypestr, "DIFF"))
    {
      img_type = PACKAGE_IMG_TYPE_SYST_DIFF;
    }
    else if(!strcmp(imgtypestr, "USER") && !strcmp(gentypestr, "DIFF"))
    {
      img_type = PACKAGE_IMG_TYPE_USER_DIFF;
    }
	else if(!strcmp(imgtypestr, "DSP3") && !strcmp(gentypestr, "DIFF"))
    {
      img_type = PACKAGE_IMG_TYPE_DSP3_DIFF;
    }
}

  if(dirType && !strcmp(directionstr, "RVS"))
  {
    img_type |= PACKAGE_IMG_TYPE_REVERSE_BM;
  }

  /* cat package info to next available slot */
  for(index = 0; index < PACKAGE_CNT_MAX_EXT; index++)
  {
    /* package ver >= 1, package info already filled */
    if(!bufferPsb[(index * PACKAGE_DESC_SIZE) + PACKAGE_VER_OFFSET])
    {
	  break;
    }  
    if((bufferPsb[(index * PACKAGE_DESC_SIZE) + PACKAGE_IMG_TYPE_OFFSET] & 
        PACKAGE_IMG_TYPE_REVERSE_BM) != 0)
    {
	  reverse_mode = true;
	}
  }

  if(index >= PACKAGE_CNT_MAX_EXT)
  {
    cout << endl << "ERROR: Package header already full " << index << endl ;
    return 0 ;
  } 

  /* check forward/reverse flages, all forward packges must be followed by reverse package, no mix */
  if(reverse_mode &&
     (img_type & PACKAGE_IMG_TYPE_REVERSE_BM) == 0)
  {
    cout << endl << "ERROR: Package forward/reverse sequence error "  << endl ;
    return 0 ;
  } 

  /* fill in the package info */
  bufferPsb[(index * PACKAGE_DESC_SIZE) + PACKAGE_VER_OFFSET] = PACKAGE_VER_CURRENT;
  bufferPsb[(index * PACKAGE_DESC_SIZE) + PACKAGE_IMG_TYPE_OFFSET] = img_type;
  if(need_reset)
  {
    bufferPsb[(index * PACKAGE_DESC_SIZE) + PACKAGE_EXT_FLAG_OFFSET] |= PACKAGE_FLAG_RESET;
  }
  /* offset = last package offset + size */
  if(index > 0)
  {
	 img_offset = readuint32nbo(&bufferPsb[((index - 1) * PACKAGE_DESC_SIZE) + PACKAGE_IMG_OFST_OFFSET]);
	 img_offset += readuint32nbo(&bufferPsb[((index - 1) * PACKAGE_DESC_SIZE) + PACKAGE_IMG_SIZE_OFFSET]);     
  }
  writeuint32nbo(img_offset, 
                 &bufferPsb[(index * PACKAGE_DESC_SIZE) + PACKAGE_IMG_OFST_OFFSET]);
  writeuint32nbo(img_size, 
                 &bufferPsb[(index * PACKAGE_DESC_SIZE) + PACKAGE_IMG_SIZE_OFFSET]);
  
  // fill in short version info - need to convert version string to short version string
  // SWI9600M_00.01.00.04 to M0010004 or (NO TAG)
  convertshortver(verstr, shortverstr);
  strncpy(&bufferPsb[(index * PACKAGE_DESC_SIZE) + PACKAGE_IMG_VER_OFFSET], 
          shortverstr, SHORTVER_SIZE) ;
  
  /* set ext flag if more than 8 packages */
  if(index >= 8)
  {
    /* adjust the image offsets since the first image will be after ext PSB  
     * in this case: 
     * CWE header + ext PSB (8th package desp and up + 2 blank records) + images
     */
    diff = ((index - 7 + 2) * PACKAGE_DESC_SIZE) + CWE_HEADER_SIZE - 
	       readuint32nbo(&bufferPsb[PACKAGE_IMG_OFST_OFFSET]);

    for(jdex = 0; jdex <= index; jdex ++)
    {
      img_offset = readuint32nbo(&bufferPsb[(jdex * PACKAGE_DESC_SIZE) + PACKAGE_IMG_OFST_OFFSET]); 
      writeuint32nbo(img_offset + diff, 
                 &bufferPsb[(jdex * PACKAGE_DESC_SIZE) + PACKAGE_IMG_OFST_OFFSET]);
      /* set EXT flag on every package descriptor - not that necessary */
      bufferPsb[(jdex * PACKAGE_DESC_SIZE) + PACKAGE_EXT_FLAG_OFFSET] |= PACKAGE_FLAG_EXT;
    }

    //-- write to ext PSB file
    outHdrFile.open(extoutputHdrFileName, ios::binary | ios::out) ;
    if (outHdrFile.is_open() == 0)
    {
      cout << endl << "ERROR: Cannot create ext output header file " << extoutputHdrFileName << endl ;
      return 0 ;
    }

    //-- Write Product Specific Buffer
    outHdrFile.write((char *)bufferPsb + PACKAGE_HEADER_SIZE, 
                      (index - 7 + 2) * PACKAGE_DESC_SIZE) ;

    outHdrFile.close() ;
  }

  //-- Create the output header file
  outHdrFile.open(outputHdrFileName, ios::binary | ios::out) ;
  if (outHdrFile.is_open() == 0)
  {
    cout << endl << "ERROR: Cannot create output header file " << outputHdrFileName << endl ;
    return 0 ;
  }

  //-- Write Product Specific Buffer
  outHdrFile.write((char *)bufferPsb, PACKAGE_HEADER_SIZE) ;

  outHdrFile.close() ;
  return 0 ;
}

/*
 * $Log: $
 *
 */



