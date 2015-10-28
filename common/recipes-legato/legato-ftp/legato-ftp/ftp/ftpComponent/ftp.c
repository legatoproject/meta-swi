/**
 * @file ftp.c
 *
 * This file contains the source code of the ftp app.
 * This application is used to download/upload files with FTP.
 * It is based on libcurl.
 *
 *  execInApp ftp download serverUrl fileName userName password dataRequest
 *  execInApp ftp upload   serverUrl fileName userName password dataRequest
 *
 *  dataRequest must be 1 if le_data_Request() should be called, 0 instead
 *
 * Copyright (C) Sierra Wireless Inc. Use of this work is subject to license.
 */


#include <arpa/inet.h>
#include <curl/curl.h>
#include "legato.h"
#include "le_data_interface.h"


#define MINIMAL_PROGRESS_FUNCTIONALITY_INTERVAL     1

#define TRUE 1
#define FALSE 0

/* TRUE means ftp download. FALSE upload */
static bool  FtpDownload = TRUE;
static char* FtpFileUrl;
static char* FtpFileName;
static char* FtpUserName;
static char* FtpPassword;
static char* FtpDataConnect;

static le_data_RequestObjRef_t RequestRef = NULL;

typedef struct Progress_s
{
    double lastruntime;
    double lastdl;
    double lastul;
    CURL *curl;
} Progress_t;

typedef struct FtpFile_s
{
    const char *filename;
    FILE *streamPtr;
} FtpFile_t;

static size_t FileWrite(void *bufferPtr, size_t size, size_t nmemb, void *streamPtr)
{
    FtpFile_t *out=(FtpFile_t *)streamPtr;
    if(out && !out->streamPtr)
    {
        /* open file for writing */
        out->streamPtr=fopen(out->filename, "wb");
        if(!out->streamPtr)
            return -1; /* failure, can't open file to write */
    }
    return fwrite(bufferPtr, size, nmemb, out->streamPtr);
}

/* this is how the CURLOPT_XFERINFOFUNCTION callback works */
static int xferinfo(void *p,
    curl_off_t dltotal, curl_off_t dlnow,
    curl_off_t ultotal, curl_off_t ulnow)
{
    Progress_t *myp = (Progress_t *)p;
    CURL *curl = (CURL *)myp->curl;
    double curtime = 0;

    curl_easy_getinfo(curl, CURLINFO_TOTAL_TIME, &curtime);

    /* under certain circumstances it may be desirable for certain
     * functionality to only run every N seconds, in order to do this the
     * transaction time can be used */
    if((curtime - myp->lastruntime) >= MINIMAL_PROGRESS_FUNCTIONALITY_INTERVAL)
    {
        float dlThroughput = (dlnow - myp->lastdl)/(curtime - myp->lastruntime);
        float ulThroughput = (ulnow - myp->lastul)/(curtime - myp->lastruntime);
        if (dlnow != 0)
            LE_INFO("Current download throughput : %f bytes/s, %f kbits/s\r\n", dlThroughput, dlThroughput*8/1024);
        if ((ulnow != 0) && (ulnow != -1))
            LE_INFO("Current upload throughput : %f bytes/s, %f kbits/s\r\n", ulThroughput, ulThroughput*8/1024);
        myp->lastruntime = curtime;
        myp->lastdl = dlnow;
        myp->lastul = ulnow;
        if (dlnow != 0)
            LE_INFO("Average download throughput : %f bytes/s\r\n", dlnow/curtime);
        if ((ulnow != 0) && (ulnow != -1))
            LE_INFO("Average upload throughput : %f bytes/s\r\n", ulnow/curtime);
        LE_INFO("TOTAL TIME: %f \r\n", curtime);

        LE_INFO("UP: %" CURL_FORMAT_CURL_OFF_T " of %" CURL_FORMAT_CURL_OFF_T
                "  DOWN: %" CURL_FORMAT_CURL_OFF_T " of %" CURL_FORMAT_CURL_OFF_T
                "\r\n",
                ulnow, ultotal, dlnow, dltotal);
    }

    if ((dlnow != 0) && (dlnow >= dltotal))
    {
        LE_INFO("Last UP: %" CURL_FORMAT_CURL_OFF_T " of %" CURL_FORMAT_CURL_OFF_T
                "  DOWN: %" CURL_FORMAT_CURL_OFF_T " of %" CURL_FORMAT_CURL_OFF_T
                "\r\n",
                ulnow, ultotal, dlnow, dltotal);
        LE_INFO("Final total time : %f \r\n", curtime);
        LE_INFO("Final average download throughput : %f bytes/s, %f kbits/s\r\n", dltotal/curtime, dltotal/curtime*8/1024);
    }
    if ((ulnow != 0) && (ulnow >= ultotal))
    {
        LE_INFO("Last UP: %" CURL_FORMAT_CURL_OFF_T " of %" CURL_FORMAT_CURL_OFF_T
                "  DOWN: %" CURL_FORMAT_CURL_OFF_T " of %" CURL_FORMAT_CURL_OFF_T
                "\r\n",
                ulnow, ultotal, dlnow, dltotal);
        LE_INFO("Final total time : %f \r\n", curtime);
        LE_INFO("Final average upload throughput : %f bytes/s, %f kbits/s\r\n", ultotal/curtime, ultotal/curtime*8/1024);
    }
    return 0;
}

// -------------------------------------------------------------------------------------------------
/**
 *  Download/Upload by FTP a file
 */
// -------------------------------------------------------------------------------------------------
int FtpGet(bool download, const char* fileUrl, const char* fileName, const char* userName, const char* password)
{
    CURL *curl;
    CURLcode res;
    FILE *hd_src = NULL;
    char completeFileUrl[256];
    FtpFile_t ftpFile=
    {
        "input.txt", /* name to store the file as if successful */
        NULL
    };
    Progress_t prog;
    struct stat file_info;
    curl_off_t fsize;

    ftpFile.filename = fileName;

    /* Concatenate URL and file name */
    snprintf( completeFileUrl, sizeof(completeFileUrl), "ftp://%s/%s", fileUrl, fileName  );

    LE_INFO("FTP_GET: %s %s %s %s %s", fileUrl, fileName, completeFileUrl, userName, password);

    curl_global_init(CURL_GLOBAL_DEFAULT);

    curl = curl_easy_init();
    if(curl)
    {
        curl_easy_setopt(curl, CURLOPT_URL,
                completeFileUrl);
        curl_easy_setopt(curl, CURLOPT_USERNAME,
                userName);
        curl_easy_setopt(curl, CURLOPT_PASSWORD,
                password);
        /* Force passive mode */
        curl_easy_setopt(curl, CURLOPT_FTP_USE_EPSV, 0);

        if (download)
        {
            /* Define our callback to get called when there's data
             * to be written */
            curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, FileWrite);

            /* Set a pointer to our struct to pass to the
             * callback */
            curl_easy_setopt(curl, CURLOPT_WRITEDATA, &ftpFile);
        }
        else
        {
            /* get the file size of the local file */
            if(stat(fileName, &file_info))
            {
                LE_ERROR("Couldnt open '%s': %s\n", fileName, strerror(errno));
                return 1;
            }
            fsize = (curl_off_t)file_info.st_size;

            /* get a FILE * of the same file */
            hd_src = fopen(fileName, "rb");
            if(!hd_src)
                return 1; /* failure, can't open file */

            /* enable uploading */
            curl_easy_setopt(curl, CURLOPT_UPLOAD, 1L);

            /* now specify which file to upload */
            curl_easy_setopt(curl, CURLOPT_READDATA, hd_src);

            curl_easy_setopt(curl, CURLOPT_INFILESIZE_LARGE,
                    (curl_off_t)fsize);
        }

        /* complete within 1000 seconds */
        curl_easy_setopt(curl, CURLOPT_TIMEOUT, 1000L);

        /* Switch on full protocol/debug output */
        curl_easy_setopt(curl, CURLOPT_VERBOSE, 1L);

        prog.lastruntime = 0;
        prog.lastdl = 0;
        prog.lastul = 0;
        prog.curl = curl;
        /* See the progress of the download */
        curl_easy_setopt(curl, CURLOPT_XFERINFOFUNCTION, xferinfo);

        curl_easy_setopt(curl, CURLOPT_XFERINFODATA, &prog);

        curl_easy_setopt(curl, CURLOPT_NOPROGRESS, 0L);

        res = curl_easy_perform(curl);

        /* always cleanup */
        curl_easy_cleanup(curl);

        if(CURLE_OK != res)
        {
            /* we failed */
            LE_ERROR("curl told us %d\n", res);
        }
    }

    if(ftpFile.streamPtr)
        fclose(ftpFile.streamPtr); /* close the local file */

    if(hd_src)
        fclose(hd_src); /* close the local file */

    curl_global_cleanup();

    return 0;
}

// -------------------------------------------------------------------------------------------------
/**
 *  In order to test out the active data connection, we simply attempt to connect to Sierra's website and
 *  report either success or failure (through TCP connection).
 */
// -------------------------------------------------------------------------------------------------
static unsigned int TestDataConnectionV4(void)
{
    int sockFd = 0;
    struct sockaddr_in servAddr;

    if ((sockFd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
    {
        LE_ERROR("Failed to create socket");
        return -1;
    }

    LE_INFO("Connecting to %s (ftp server)\n", FtpFileUrl);

    servAddr.sin_family = AF_INET;
    servAddr.sin_port = htons(80);
    servAddr.sin_addr.s_addr = inet_addr(FtpFileUrl);

    if (connect(sockFd, (struct sockaddr *)&servAddr, sizeof(servAddr)) < 0)
    {
        LE_ERROR("Failed to connect to the FTP server: %s", strerror(errno));
        return -1;
    }
    else
    {
        LE_INFO("Connection to the FTP server was successful.");
    }

    close(sockFd);
    return 0;
}
// -------------------------------------------------------------------------------------------------
/**
 *  Event callback for connection state changes.
 */
// -------------------------------------------------------------------------------------------------
static void ConnectionStateHandler
(
    const char *intfName,
    bool   isConnected,
    void*  contextPtr
)
{
    LE_INFO("Connection State Event: '%s' %s",
            intfName,
            (isConnected) ? "connected" : "not connected");

    if (!isConnected)
    {
        LE_INFO("Data connection: not connected.");
    }
    else
    {
        LE_INFO("Data connection: connected.");
        sleep(5);
        if (TestDataConnectionV4() == 0)
        {
          if (FtpGet(FtpDownload, FtpFileUrl, FtpFileName, FtpUserName, FtpPassword) == 0)
            exit(EXIT_SUCCESS);
          else
            exit(EXIT_FAILURE);
        }
    }
}

COMPONENT_INIT
{
    int argNb = (int)le_arg_NumArgs();

    if (argNb != 6)
    {
        LE_ERROR("Not enough arguments");
        exit(EXIT_FAILURE);
    }
    else
    {
        if (strncmp((char*)le_arg_GetArg(0), "download", 8) == 0)
            FtpDownload = TRUE;
        else if (strncmp((char*)le_arg_GetArg(0), "upload", 6) == 0)
            FtpDownload = FALSE;
        FtpFileUrl  = (char*)le_arg_GetArg(1);
        FtpFileName = (char*)le_arg_GetArg(2);
        FtpUserName = (char*)le_arg_GetArg(3);
        FtpPassword = (char*)le_arg_GetArg(4);
        FtpDataConnect = (char*)le_arg_GetArg(5);
        LE_INFO("%s %s %s %s %s", FtpFileUrl, FtpFileName, FtpUserName, FtpPassword, FtpDataConnect);
    }

    LE_INFO("FTP download/upload application");

    if (memcmp(FtpDataConnect, "1", 1) == 0)
    {
        RequestRef = le_data_Request();

        // register handler for connection state change
        le_data_AddConnectionStateHandler(ConnectionStateHandler, NULL);
    }
    else
    {
        if (FtpGet(FtpDownload, FtpFileUrl, FtpFileName, FtpUserName, FtpPassword) == 0)
            exit(EXIT_SUCCESS);
        else
            exit(EXIT_FAILURE);
    }
}
