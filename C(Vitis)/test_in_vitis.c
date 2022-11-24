#include <stdio.h>
#include "xparameters.h"
#include "xil_io.h"         /* to use xil_printf*/
#include "xtime_l.h"        /* to measure time*/
#include <stdlib.h>
#include "xsdps.h"		    /* SD device driver */
#include "ff.h"             /* file read and write to register */

#define N 100000 // get 100000 samples!

#define AXI_DATA_BYTE 4 // data width of axi4-lite is 32bits

#define IDLE 1 // IDLE state : p-bits model is not Running
#define RUN 1 << 1 // RUN state : p-bit model is calculating(Running)
#define DONE 1 << 2 // DONE state: stop calculating and go back to IDLE state

#define CTRL_REG 0 		// slv_reg0: [R/W] Used to control the p-bit model
#define STATUS_REG 1 	// slv_reg1: [Read only] Used to check status(IDLE, RUN, DONE) of the p-bit model
#define M0_REG 2		// slv_reg2: [Read only] Used to get m0 value
#define M1_REG 3        // slv_reg3: [Read only] Used to get m1 value
#define M0_INI_REG 4    // slv_reg4: [Write only] Used to send initial value of m0 to p-bit model
#define M1_INI_REG 5    // slv_reg5: [Write only] Used to send initial value of m1 to p-bit model
#define BETA_REG 6		// slv_reg6: [Write only] Used to send beta to p-bit model


int main() {

	// 1. declare the variables

	/* Declare required variables */

	int choice = 0;   			 // determine whether to start the program
    int idle;         			 // to check whether the state is IDLE
    int done;	      			 // to check whether the state is DONE

    int* m0_pointer;  			 // to store value of m0 temporally
    int* m1_pointer;  			 // to store value of m1 temporally


    int m0_initial, m1_initial;  // to store the
    int beta = 0;                // to store the value of beta
    XTime tStart, tEnd;          // to measure time


    /* Declare variables for file reading and writing */

	static FIL fil; 		/* file object */
	static FATFS fatfs; 	/* file system object */
	FRESULT Res;			/* to detect error while reading or writing a file */
	TCHAR *Path = "0:/";    /* SD CARD path */
	BYTE work[FF_MAX_SS];   /* working buffer for f_mkfs */

	static char FileName[32] = "p-bit.txt"; /* file name */
	static char *SD_File;


	// 2. start the program


    while(1){
    	xil_printf("======= p-bit started ======\n");

    	xil_printf("start(1) / terminate(0): \n");
    	scanf("%d", &choice);


    	if(choice == 1){


    		// 3. prepare Read and Write to SD card


    		/* gives work area to the FatFs module and initialize logical drive(SD CARD) */

    		Res = f_mount(&fatfs, Path, 0);

			if(Res != FR_OK){
				xil_printf("f_mount failed");
				return XST_FAILURE;
			}


			/* creates an FAT/exFAT volume on the logical drive. */

			Res = f_mkfs(Path, FM_FAT32, 0, work, sizeof work);

			if(Res != FR_OK){
				xil_printf("f_mkfs failed\n");
				return XST_FAILURE;
			}


			/* creating new file with read/write permissions */
			/* to open file with write permissions, file system should not be in Read only mode */

			SD_File = (char *)FileName;

			Res = f_open(&fil, SD_File, FA_CREATE_ALWAYS | FA_WRITE | FA_READ);
			if (Res) {
				xil_printf("f_open failed\n");
				xil_printf("Error code is %d", Res);
				return XST_FAILURE;
			}


			/* Pointer which is pointing to where the file starts */

			Res = f_lseek(&fil, 0);
			if (Res) {
				xil_printf("f_lseek failed\n");
				return XST_FAILURE;

			}


			// 4. initialize registers and send m0_initial, m1_initial, beta


			/* initialize registers to zero */

			Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)(0x00000000));
			Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (M0_INI_REG*AXI_DATA_BYTE), (u32)(0x00000000));
			Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (M1_INI_REG*AXI_DATA_BYTE), (u32)(0x00000000));
			Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (BETA_REG*AXI_DATA_BYTE), (u32)(0x00000000));


			/* time measure : to get a random number seed */

			XTime_GetTime(&tStart);


			/* create an array using malloc function */

			m0_pointer = (int *)malloc(sizeof(int)*N);
			m1_pointer = (int *)malloc(sizeof(int)*N);

			XTime_GetTime(&tEnd);


			/* send initial value of m0, m1 to register */

			srand(tEnd - tStart);

			m0_initial = rand()%2;


			srand(2*(tEnd - tStart));

			m1_initial = rand()%2;


			Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (M0_INI_REG*AXI_DATA_BYTE), (u32)m0_initial);
			Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (M1_INI_REG*AXI_DATA_BYTE), (u32)m1_initial);


			/* send beta to register */

			xil_printf("beta!: ");
			scanf("%d", &beta);
			Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (BETA_REG*AXI_DATA_BYTE), (u32)beta);


			// 5. start the p-bit calcaulation


			/* check whether the state is IDLE */
			do{
				idle = Xil_In32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (STATUS_REG*AXI_DATA_BYTE));
			} while( (idle & IDLE) != IDLE);


			/* start the p-bit calculation */

			Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)0x80000000); // send the run signal

			for(int i = 0; i < N; i++){

				m0_pointer[i] = Xil_In32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (M0_REG*AXI_DATA_BYTE)); // receive calculated m0 value from p-bit model

				m1_pointer[i] = Xil_In32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (M1_REG*AXI_DATA_BYTE)); // receive calculated m1 value from p-bit model

			}


			// 6. stop the p-bit calcaulation


			/* send a stop signal to p-bit model */

			Xil_Out32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (CTRL_REG*AXI_DATA_BYTE), (u32)0x40000000); // send the input


			/* check whether the state is DONE */

			do{
				done = Xil_In32((XPAR_TOP_MODULE_OF_ENTIRE_0_BASEADDR) + (STATUS_REG*AXI_DATA_BYTE));
			} while( (done & DONE) != DONE );


			// 7. write the value of m0 and m1 to SD card


			for(int i=0;i<N;i++){
				f_printf(&fil, "%d", m0_pointer[i]);
				f_printf(&fil, "%d\n", m1_pointer[i]);
			}


			//8. file close and finish the model


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
