

//##########################################################################
// AXEL
//##########################################################################
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#define BUFSIZE (200*1024)
#define PYBUFSIZE (8*1024)
typedef struct saveFile 
{
    FILE *fd;
    char fName[255];
    char fName2[255];
    char dataString[255];
    char dataString2[255];
    char bigBuf[BUFSIZE];
    
    int fNum;
    int nWrite;
    int initDone;
    int bigBufIndex;
	int chan;
    long long data;
}saveFile;


saveFile mySaveFile;
saveFile mySaveFile2;
saveFile mySaveFile3;

long long calcTime2(struct timeval *tv_old) {
   struct timeval tv_new;
   struct timeval tv_diff;

   gettimeofday(&tv_new, 0);
   tv_diff.tv_usec = tv_new.tv_usec - tv_old->tv_usec;
   tv_old->tv_usec = tv_new.tv_usec;
   return tv_diff.tv_usec; 
}

void saveToFilePytime2(saveFile *mySaveFile)
{ 
    struct timeval tv_cur;
    static timeval tv_old;
    int ret;
    pid_t myPid = getpid();
    
    gettimeofday(&tv_cur, 0);

    if (mySaveFile->bigBufIndex >= (PYBUFSIZE - 1024)) {
        sprintf(mySaveFile->fName2,"/dev/shm/axPytime%04d.txt",
                mySaveFile->fNum);
		mySaveFile->fd = fopen(mySaveFile->fName2,"w");
		fwrite(mySaveFile->bigBuf, mySaveFile->bigBufIndex, 1, mySaveFile->fd);
		if (mySaveFile->fd)
			fclose(mySaveFile->fd);

		mySaveFile->fd = 0;
		mySaveFile->nWrite = 0;
		mySaveFile->fNum++;
		mySaveFile->bigBufIndex = 0;

    }
    ret += sprintf(&mySaveFile->bigBuf[mySaveFile->bigBufIndex],"            %s-%d  [001]  %d.%06d: %s <-%s\n",__FILE__,
                myPid, tv_cur.tv_sec, tv_cur.tv_usec, mySaveFile->dataString, mySaveFile->dataString2);

    mySaveFile->bigBufIndex += ret;

    return;
}


void writeFile(saveFile *mySaveFile)
{ 

    int ret;


    if (mySaveFile->bigBufIndex >= (BUFSIZE - 1024)) {
		sprintf(mySaveFile->fName2,"/dev/shm/axdata%04d_%d.txt",
			mySaveFile->fNum, mySaveFile->chan);
		mySaveFile->fd = fopen(mySaveFile->fName2,"w");
		fwrite(mySaveFile->bigBuf, mySaveFile->bigBufIndex, 1, mySaveFile->fd);
        if (mySaveFile->fd)
            fclose(mySaveFile->fd);

        mySaveFile->fd = 0;
		mySaveFile->nWrite = 0;
		mySaveFile->fNum++;
		mySaveFile->bigBufIndex = 0;

    }
    ret += sprintf(&mySaveFile->bigBuf[mySaveFile->bigBufIndex],
		"%s\n", mySaveFile->dataString);

    mySaveFile->bigBufIndex += ret;

    return;
}

inline void flog(const char* func, int line) {

    if (!mySaveFile.initDone) {
        mySaveFile.fNum= 0;
        mySaveFile.initDone = 1;
    }

    snprintf(mySaveFile.dataString, 255, "%s", func);
    snprintf(mySaveFile.dataString2, 255,"%d",line);
    saveToFilePytime2(&mySaveFile);
}

inline void saveToFileWithTime(unsigned char* data, int size) {
	short *p1 = (short *) data;
	struct timeval tv_now;
	unsigned int offset = 0;

	gettimeofday(&tv_now, 0);
	if (!mySaveFile2.initDone) {
		mySaveFile2.fNum= 0;
		mySaveFile2.initDone = 1;
		mySaveFile2.chan = 1;
	}
	if (!mySaveFile3.initDone) {
		mySaveFile3.fNum= 0;
		mySaveFile3.initDone = 1;
		mySaveFile3.chan = 2;
	}

	int flag = 0;
	for (int i = 0; i < size/2; ) {
			if (i==0)
				flag =1;
			else
				flag = 0;
			short d = p1[i++];
			short d2 = p1[i++];

			if (flag)  {
				d = 0x7FFF;	
				d2 = 0x7FFF;
			}
			snprintf(mySaveFile2.dataString, 255, "%ld.%06ld %d", tv_now.tv_sec, tv_now.tv_usec + offset, d);
			writeFile(&mySaveFile2);
			snprintf(mySaveFile3.dataString, 255, "%ld.%06ld %d", tv_now.tv_sec, tv_now.tv_usec + offset, d2);
			writeFile(&mySaveFile3);
			offset += 23;
	}
}

inline void saveToFile(unsigned char* data, int size) {
	short *p1 = (short *) data;

	if (!mySaveFile2.initDone) {
		mySaveFile2.fNum= 0;
		mySaveFile2.initDone = 1;
		mySaveFile2.chan = 1;
	}
	if (!mySaveFile3.initDone) {
		mySaveFile3.fNum= 0;
		mySaveFile3.initDone = 1;
		mySaveFile3.chan = 2;
	}

	int flag = 0;
	for (int i = 0; i < size/2; ) {
			if (i==0)
				flag =1;
			else
				flag = 0;
			short d = p1[i++];
			short d2 = p1[i++];

			if (flag)  {
				d = 0x7FFF;	
				d2 = 0x7FFF;
			}
			snprintf(mySaveFile2.dataString, 255, "%d", d);
			writeFile(&mySaveFile2);
			snprintf(mySaveFile3.dataString, 255, "%d", d2);
			writeFile(&mySaveFile3);
	}
}

#define S1  (1024)
#define RANGE 0x800
#define DATA1 (0x0000)
#define DATA2 RANGE

void fillFreq(char* data, int size, int freq)
{
	unsigned short *p1 = (unsigned short *)data;
	int size2 = size/2;
	static unsigned short curData = DATA1;
	
	for (int i = 0; i < size2;) {
		if (!(i%freq)) {
			(curData == DATA1) ? curData = DATA2 :curData = DATA1;
		}
		p1[i++] = curData;
		p1[i++] = curData;
	}
	return;
}

void fillFreq2(char* data, int size, int freq, int *reset)
{
    int i = 0;
    int j = 0;
    static unsigned short  val = 0;
	static int dir = 1;
    unsigned int cyclePerSec = freq;
    int numSamplesPerSec = 44100;
    int numSamplesPerCycle =  numSamplesPerSec / cyclePerSec;
	
    short maxAmp = 0X7FFF;
    short minAmp = maxAmp * -1;
    int stepSize = maxAmp / (numSamplesPerCycle * 2);
	unsigned short *p1 = (unsigned short *)data;
	//int numCycles = songDurationSec * cyclePerSec *  2;
	if (*reset) {
		val = minAmp;
		dir = 1;
		*reset = 0;
	}
 
        for (int i = 0; i < size/2;) {

			if (dir)
                val += stepSize;
            else
                val -= stepSize;

            if (val <= (minAmp + stepSize))
                dir = 1;
            if (val >= (maxAmp - stepSize))
                dir = 0;

            p1[i++] = val;
			p1[i++] = val;
        }


    return;
}

//##########################################################################
// AXEL END
//##########################################################################


