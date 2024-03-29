!!****if* source/Grid/GridMain/gr_GCReleaseScratch
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
!!  gr_GCReleaseScratch
!!
!! SYNOPSIS
!!
!!  call gr_GCReleaseScratch(integer(IN) :: gridDataStruct)
!!  
!!  
!! DESCRIPTION
!!  
!!  This routine releases the space set up by a call to 
!!  gr_GCAllocScratch for storing guardcells.
!!
!! ARGUMENTS
!!            
!!  gridDataStruct : integer value specifying data structure. 
!!                   The options are defined in constants.h, the ones
!!                   relevant to this routine are :
!!                   CENTER cell centered variables (default)
!!                   FACEX  face centered variable on faces along IAXIS
!!                   FACEY  face centered variable on faces along JAXIS
!!                   FACEZ  face centered variable on faces along IAXIS
!!               
!!
!!  NOTES
!!   variables that start with "gr_" are variables of Grid unit scope
!!   and are stored in the fortran module Grid_data. Variables are not
!!   starting with gr_ are local variables or arguments passed to the 
!!   routine.
!!
!!  SEE ALSO
!!
!!   gr_GCAllocScratch
!!
!!***

#include "constants.h"
#include "Simulation.h"

subroutine gr_GCReleaseScratch(gridDataStruct)

  use gr_GCScratchData

  implicit none

  integer, intent(IN) :: gridDataStruct

  select case(gridDataStruct)
  case(CENTER)
     deallocate(gr_GCCtrIndList)
     deallocate(gr_GCCtrBlkList)
     deallocate(gr_GCCtrBlkOffsets)
     deallocate(gr_GCCtr)
  case(FACEX)
     deallocate(gr_GCFxIndList)
     deallocate(gr_GCFxBlkList)
     deallocate(gr_GCFxBlkOffsets)
     deallocate(gr_GCFx)
  case(FACEY)
     deallocate(gr_GCFyIndList)
     deallocate(gr_GCFyBlkList)
     deallocate(gr_GCFyBlkOffsets)
     deallocate(gr_GCFy)
  case(FACEZ)
     deallocate(gr_GCFzIndList)
     deallocate(gr_GCFzBlkList)
     deallocate(gr_GCFzBlkOffsets)
     deallocate(gr_GCFz)
  end select
end subroutine gr_GCReleaseScratch
