!!****if* source/IO/IOMain/IO_outputInitial
!! NOTICE
!!  Copyright 2022 UChicago Argonne, LLC and contributors
!!
!!  Licensed under the Apache License, Version 2.0 (the "License");
!!  you may not use this file except in compliance with the License.
!!
!!  Unless required by applicable law or agreed to in writing, software
!!  distributed under the License is distributed on an "AS IS" BASIS,
!!  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
!!  See the License for the specific language governing permissions and
!!  limitations under the License.
!!
!! NAME
!!
!!  IO_outputInitial
!!
!!
!! SYNOPSIS
!!
!!
!!  IO_outputInitial(integer(in) :: nbegin,
!!                   real(in) :: initialSimTime  
!!                  
!!
!!
!! DESCRIPTION
!!
!!
!!  This routine is called before the main timestep loop.  It outputs the 
!!  initial data to a checkpoint file and plotfile, and particle plotfiles
!!
!!  If particles are not included a stub (empty) routine will be called.
!!
!!
!! ARGUMENTS
!!
!!  nbegin - initial step of simulation
!!  initialSimTime - initial simulation time
!!
!! SIDE EFFECTS
!!
!!  The state of module level logical variable io_outputInStack.
!!
!!***


subroutine IO_outputInitial( nbegin, initialSimTime)

#include "constants.h"
  use IO_data, ONLY : io_integralFreq, io_memoryStatFreq, &
       io_redshift, io_justCheckpointed, io_restart, &
       io_alwaysComputeUserVars, io_outputInStack, io_summaryOutputOnly
  use Grid_interface, ONLY : Grid_restrictAllLevels, &
    Grid_computeUserVars
  use IO_interface, ONLY : IO_writeIntegralQuantities, &
    IO_writeCheckpoint, IO_writePlotfile, IO_writeParticles

#include "Flashx_mpi_implicitNone.fh"
  integer, intent(in) :: nbegin
  real, intent(in) :: initialSimTime
  logical :: forcePlotfile
 
  forcePlotfile = .false.

  !This setting is used to ensure valid data throughout grid and ancestor blocks
  io_outputInStack = .true.

  !------------------------------------------------------------------------------
  ! Dump out memory usage statistics if we are monitoring them,
  ! BEFORE opening files for output for the first time.
  !------------------------------------------------------------------------------
  if (io_memoryStatFreq > 0) call io_memoryReport()

  !write the diagnostic quantities for the .dat file
  if(io_integralFreq > 0) then
     call IO_writeIntegralQuantities( 1, initialSimTime)
  end if

  if(.not. io_alwaysComputeUserVars) call Grid_computeUserVars()
  
  if (.not.io_summaryOutputOnly) then
     if(.not. io_restart) then
        call IO_writeCheckpoint()
        io_justCheckpointed = .true.
     else
        io_justCheckpointed = .false.
     end if

     if( io_restart) forcePlotfile = .true.
     call IO_writePlotfile(forcePlotfile)
!! Devnote :: preprocessors because amrex particles are being handled through amrex grid
#ifndef FLASH_GRID_AMREX
     call IO_writeParticles( .false.)
#endif
  else
     io_justCheckpointed = .false.
  end if

  !------------------------------------------------------------------------------
  ! Dump out memory usage statistics again if we are monitoring them,
  ! AFTER having written the initial output files.
  !------------------------------------------------------------------------------
  if (io_memoryStatFreq > 0) call io_memoryReport()
  io_outputInStack = .false.

end subroutine IO_outputInitial
