!!****if* source/Grid/GridMain/Chombo/gr_writeBlockInfo
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
!!  gr_writeBlockInfo
!!
!! SYNOPSIS
!!
!!  call gr_writeBlockInfo()
!!
!!
!! DESCRIPTION 
!!  
!!  Writes various block information to a local log file for debugging purposes.
!!  Each process writes information about all blocks that it owns.
!!
!! ARGUMENTS 
!!
!!***

#include "flash_bool.h"
#include "constants.h"
#include "Simulation.h"

subroutine gr_writeBlockInfo
  use iso_c_binding,     ONLY : c_int
  use Logfile_interface, ONLY : Logfile_open, Logfile_close
  use Driver_interface,  ONLY : Driver_getSimTime, &
                                Driver_getNStep, &
                                Driver_abort

  implicit none

  real :: simTime
  integer(c_int) :: b
  integer :: i, d, count, logUnit, nstep
  logical, dimension(MDIM) :: isNextToLowDomain, isNextToHighDomain
  
  logical, parameter :: localLogFile = .true.

  !The introduction format string:
  character (len=*), parameter  :: introStr = &
       "(/ a,i8 / a,es12.4 / a,i8 /)"

  !The block information format string:
  character (len=*), parameter  :: baseStr = &
       "( a,i8 / a,i8 /"
  character (len=*), parameter  :: logStr1d = &
       "a,i8 / a,i8 / a,i8 / a,i8 / a,es14.6 / a,es14.6 / a,l8 / a,l8 /)"
  character (len=*), parameter  :: logStr2d = &
       "a,2i8 / a,2i8 / a,2i8 / a,2i8 / a,2es14.6 / a,2es14.6 / a,2l8 / a,2l8 /)"
  character (len=*), parameter  :: logStr3d = &
       "a,3i8 / a,3i8 / a,3i8 / a,3i8 / a,3es14.6 / a,3es14.6 / a,3l8 / a,3l8 /)"
#if NDIM == 1
  character (len=len(baseStr)+len(logStr1d)) :: logStr
  logStr = baseStr // logStr1d
#elif NDIM == 2
  character (len=len(baseStr)+len(logStr2d)) :: logStr
  logStr = baseStr // logStr2d
#elif NDIM == 3
  character (len=len(baseStr)+len(logStr3d)) :: logStr
  logStr = baseStr // logStr3d
#endif

  call Driver_getNStep(nstep)
  call Driver_getSimTime(simTime)
  call Logfile_open(logUnit,localLogFile)
  call Grid_getListOfBlocks(ALL_BLKS,listOfBlocks,count)
  
  write(logUnit,introStr) &
       " Nstep:", nstep, &
       " Sim time:", simTime, &
       " Num. local blocks:", count

   ! DEV: TODO Implement for AMReX
!  do i = 1, count
!     b = listOfBlocks(i)
!     call ch_get_box_info(b, CENTER, boxInfo)
!     
!     do d = 1, NDIM
!        isNextToLowDomain(d) = (boxInfo % isNextToLowDomain(d) == FLASH_TRUE)
!        isNextToHighDomain(d) = (boxInfo % isNextToHighDomain(d) == FLASH_TRUE)
!     end do
!
!     write(logUnit,logStr) &
!          " Block ID:", b, &
!          " refinement level:", boxInfo % lrefine, &
!          " level low index: ", boxInfo % lowLimits(1:NDIM), &
!          " level high index:", boxInfo % highLimits(1:NDIM), & 
!          " corner ID:       ", boxInfo % corner(1:NDIM), & 
!          " stride:          ", boxInfo % stride(1:NDIM), & 
!          " low bound box: ", boxInfo % lowBndbox(1:NDIM), &
!          " high bound box:", boxInfo % highBndbox(1:NDIM), &
!          " next to low domain: ", isNextToLowDomain(1:NDIM), &
!          " next to high domain:", isNextToHighDomain(1:NDIM)
!  end do

  call Logfile_close(localLogFile)

  ! DEV: TODO Implement this with iterator if needed
  call Driver_abort("[gr_writeBlockInfo] not implemented for AMReX yet")

end subroutine gr_writeBlockInfo

