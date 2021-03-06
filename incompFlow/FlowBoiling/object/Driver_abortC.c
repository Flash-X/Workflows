/****if* source/Driver/DriverMain/Driver_abortC
*
* NAME
*
*  Driver_abortC
*
* SYNOPSIS
*
*  Driver_abortC(char* :: errorMessage)
*
* DESCRIPTION
*
*  C specific function that writes an error message int Driver_abortC_myPE;

*  to the logfile and aborts FLASHX.
*  Attempts to shut down all processes (using MPI_Abort()).
*  
*  Use this function to abort the FLASH code from a C routine
*  
*
* ARGUMENTS
*
*  errorMessage:     A string to write to the logfile (presumably 
*                    indicating what went wrong).
*
* NOTES
*  for those familiar with FLASH2, we added this function to make it
*  easier to compile FLASH across different compilers.  It is possible
*  to call fortran90 routines from C functions, however an interface
*  is needed and some complications were found on various compilers.
*  Often users had to remove all the calls to abort_flash in the io 
*  C routines in order to get FLASH2 to run.  
*
*
***/


#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include "mpi.h"
#include "constants.h"
#include "mangle_names.h"

int Driver_abortC_myPE;
int Driver_abortC_abortPause = 0;

int Driver_abortC(char* message){

  int errorcode = 1;
  int ierr, myPE;

  myPE = Driver_abortC_myPE;

  if(myPE == MASTER_PE){
      fflush(stderr);
      printf("Driver_abortC called\n");
      printf("%s\n", message);
      printf("Calling MPI_Abort for immediate shutdown\n");
      fflush(stdout);
  } else {
      fprintf(stderr,"DRIVER_ABORT: %s\n", message);
      fflush(stderr);
  }

  if (Driver_abortC_abortPause > 0) {
      sleep(Driver_abortC_abortPause);
  }

  ierr = MPI_Abort(MPI_COMM_WORLD, errorcode);

  /*This should not be returning.  If it does, the process should die.
    This should force the MPI implementation to kill the rest of the jobs.
    --PR*/

  return ierr;

}

void FTOC(driver_abortc_set_mype)(int* myPE){
  Driver_abortC_myPE = *myPE;
  return;
}
void FTOC(driver_abortc_set_pause)(int* abortPause){
  Driver_abortC_abortPause = *abortPause;
  return;
}
