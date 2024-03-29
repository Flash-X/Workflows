!!****if* source/Driver/DriverMain/Driver_sendOutputData
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
!!  Driver_sendOutputData
!!
!! SYNOPSIS
!! 
!!  Driver_sendOutputData()
!!  
!! DESCRIPTION 
!!
!! This routine sends the scalar variables owned by the Driver unit
!! like time and dt to the IO unit, to be written to a checkpoint file.
!!
!!
!! NOTES
!!
!! The Driver unit uses a few unit scope variables that are
!! accessible to all routines within the unit, but not to the
!! routines outside the unit. These variables begin with "dr_"
!! like, dr_globalMe or dr_dt, dr_beginStep, and are stored in FORTRAN
!! module Driver_data (in file Driver_data.F90). The other variables
!! are local to the specific routine and do not have the prefix "dr_"
!!
!!
!!***

subroutine Driver_sendOutputData()

  use Driver_data, ONLY : dr_dt, dr_simTime, dr_nbegin, dr_nstep, dr_dtOld,&
                          dr_dtSTS, dr_dtNew, dr_initialSimTime,&
                          dr_redshift, dr_redshiftOld, dr_axisNumProcs
  use IO_interface, ONLY :  IO_setScalar

  implicit none

  if (dr_nstep == dr_nbegin  &
       .AND. dr_simTime == dr_initialSimTime) then
     ! should only be true if we are BEFORE the Driver_evolveAll loop - KW
     call IO_setScalar("nstep", dr_nstep)
  else
     call IO_setScalar("nstep", dr_nstep+1)
  end if

  call IO_setScalar("time", dr_simTime)
  call IO_setScalar("dt", dr_dt)
  call IO_setScalar("dtOld", dr_dtOld)
  call IO_setScalar("dtSTS", dr_dtSTS)
  call IO_setScalar("dtNew", dr_dtNew)
  call IO_setScalar("nbegin", dr_nbegin)
  call IO_setScalar("redshift", dr_redshift)
  call IO_setScalar("redshiftOld", dr_redshiftOld)
  call IO_setScalar("iprocs", dr_axisNumProcs(1))
  call IO_setScalar("jprocs", dr_axisNumProcs(2))
  call IO_setScalar("kprocs", dr_axisNumProcs(3))


end subroutine Driver_sendOutputData

