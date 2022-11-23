#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"
#include "xtime_l.h"  // To measure of cycles
#include <stdlib.h>
#include "xsdps.h"		/* SD device driver */
#include "ff.h"
#include "xil_cache.h"
#include "xplatform_info.h"
#include <string.h>

#define N 100000

#define AXI_DATA_BYTE 4 // data width of axi4-lite is 32bits

#define IDLE 1 // IDLE state: wait for RUN state
#define RUN 1 << 1 // RUN state: generate random number
#define DONE 1 << 2 // DONE state: stop generating randoom number and go back to IDLE state

#define CTRL_REG 0 		// [R/W] register that is used to control the core(random number generator)
#define STATUS_REG 1 	// [R only] register that is used to check status(IDLE, RUN, DONE) of the core
#define M0_REG 2		// [R only] register that is used to get m0 value
#define M1_REG 3        // [R only] register that is used to get m1 value
#define M0_INI_REG 4
#define M1_INI_REG 5
#define BETA_REG 6


int main() {
	int choice = 0;
    int idle;
    int done = 0;

    int* m0_pointer;
    int* m1_pointer;


    int m0_initial, m1_initial;
    int beta = 0;
    XTime tStart, tEnd;

    /*for file read and write*/
	static FIL fil; /*file object*/
	static FATFS fatfs; /*file system object*/
	FRESULT Res;
	TCHAR *Path = "0:/"; /*SD CARD path*/
	BYTE work[FF_MAX_SS]; // working buffer for f_mkfs

	static char FileName[32] = "Rand.txt"; /*file name*/
	static char *SD_File;


    while(1){
    	xil_printf("======= p-bit started ======\n");

    	xil_printf("start(1) / terminate(0): \n");
    	scanf("%d", &choice);


    	if(choice == 1){

    		Res = f_mount(&fatfs, Path, 0); /* gives work area to the FatFs module and initialize logical drive(SD CARD)*/

			if(Res != FR_OK){
				xil_printf("f_mount failed");
				return XST_FAILURE;
			}

			// creates an FAT/exFAT volume on the logical drive.

			Res = f_mkfs(Path, FM_FAT32, 0, work, sizeof work);

			if(Res != FR_OK){
				xil_printf("f_mkfs failed\n");
				return XST_FAILURE;
			}

			// creating new file with read/write permissions
			// to open file with write permissions, file system should not be in Read only mode
			SD_File = (char *)FileName;

			Res = f_open(&fil, SD_File, FA_CREATE_ALWAYS | FA_WRITE | FA_READ);
			if (Res) {
				xil_printf("f_open failed\n");
				xil_printf("Error code is %d", Res);
				return XST_FAILURE;
			}


			// pointer to beginning of file
			Res = f_lseek(&fil, 0);
			if (Res) {
				xil_printf("f_lseek failed\n");
				return XST_FAILURE;

			}


			// initialize register to zero
				Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x00000000));
				Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (M0_INI_REG*AXI_DATA_BYTE), (u32)(0x00000000));
				Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (M1_INI_REG*AXI_DATA_BYTE), (u32)(0x00000000));
				Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (BETA_REG*AXI_DATA_BYTE), (u32)(0x00000000));


			XTime_GetTime(&tStart); // to get a random number seed
		    // create an array using malloc
			m0_pointer = (int *)malloc(sizeof(int)*N);
			m1_pointer = (int *)malloc(sizeof(int)*N);
			XTime_GetTime(&tEnd); // // to get a random number seed

			// put a random number(initial value) on m0, m1
				srand(tEnd - tStart);

				if(rand()%2 == 1)
					m0_initial = 1;
				else
					m0_initial = -1;

				srand(2*(tEnd - tStart));

				if(rand()%2 == 1)
					m1_initial = 1;
				else
					m1_initial = -1;

				//xil_printf("%d", m0_initial);
				//xil_printf("%d", m1_initial);

				Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (M0_INI_REG*AXI_DATA_BYTE), (u32)m0_initial);
				Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (M1_INI_REG*AXI_DATA_BYTE), (u32)m1_initial);


			// put a beta
				xil_printf("beta!: ");
				scanf("%d", &beta);
				Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (BETA_REG*AXI_DATA_BYTE), (u32)beta);


				XTime_GetTime(&tStart);
				// check whether the state is IDLE
				do{
					idle = Xil_In32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (STATUS_REG*AXI_DATA_BYTE));
				} while( (idle & IDLE) != IDLE);


			///////// start the core

				Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)0x80000000); // send the run signal

				for(int i = 0; i < N; i++){


					m0_pointer[i] = Xil_In32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (M0_REG*AXI_DATA_BYTE));
					//if(m0_pointer[i] == 2)
					//	m0_pointer[i] = 1;


					m1_pointer[i] = Xil_In32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (M1_REG*AXI_DATA_BYTE));
					//if(m1_pointer[i] == 2)
					//	m1_pointer[i] = 1;


					//xil_printf("m0, m1 is (%d, %d)\n", m0_pointer[i], m1_pointer[i]);

				}

				// send a stop signal

				Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)0x40000000); // send the input


				// check whether the state is DONE


				do{
					done = Xil_In32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (STATUS_REG*AXI_DATA_BYTE));
				} while( (done & DONE) != DONE );

				XTime_GetTime(&tEnd);
				//printf("Output took %llu clock cycles.\n", 2*(tEnd - tStart));
				printf("Output took %.2f us.\n", 1.0 * (tEnd - tStart) / (COUNTS_PER_SECOND/1000000));


				for(int i=0;i<N;i++){
					f_printf(&fil, "%d", m0_pointer[i]);
					f_printf(&fil, "%d\n", m1_pointer[i]);
				}


				Res = f_close(&fil);
				if(Res){
					return XST_FAILURE;
				}
				xil_printf("Successfully ran! \n");


				free(m0_pointer);
				free(m1_pointer);

			xil_printf("Done\n");
    	}

    	else
    		break;

    }
    xil_printf("It is over!\n");
    return 0;
}
