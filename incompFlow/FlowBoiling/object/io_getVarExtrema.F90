!!****if* source/IO/IOMain/io_getVarExtrema
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
!!  io_getVarExtrema
!!
!!
!! SYNOPSIS
!!
!!  io_getVarExtrema(integer(in) :: nvars,
!!                   real(out)   :: globalVarMin(nvars),
!!                   real(out)   :: globalVarMax(nvars),
!!                   integer(in) :: gridDataStruct)
!!          
!!
!!
!!
!! DESCRIPTION
!!
!!  This function gets the maximum and minimum values for each variable 
!!  stored in the kind of array that is indicated by gridDataStruct.
!!
!! ARGUMENTS
!! 
!!  nvars - the number of mesh variables in gridDataStruct
!!  globalVarMin - array holding max value for each variable in the data structure
!!  globalVarMax - array holding min value for each variable in the data structure
!!  gridDataStruct - one of CENTER (for UNK), SCRATCH, or FACE{X,Y,Z}
!!
!! NOTES
!!
!!***


!!REORDER(4): solnData

subroutine io_getVarExtrema(nvars, globalVarMin, globalVarMax, gridDataStruct)
      use Grid_interface, ONLY : Grid_getTileIterator, &
                                 Grid_releaseTileIterator
      use Driver_interface, ONLY : Driver_abort
      use IO_data, only: io_unkToGlobal, io_globalComm
      use Grid_iterator, ONLY : Grid_iterator_t
      use Grid_tile,     ONLY : Grid_tile_t 
      
#include "Flashx_mpi_implicitNone.fh"
#include "constants.h"
#include "Simulation.h"
#ifdef Grid_releaseBlkPtr
! doing Grid_releaseBlkPtr macro expansion by hand because otherwise
! it generates too long of a line for the fortran compiler, see: drift
#undef Grid_releaseBlkPtr
#endif

      integer, intent(in) :: nvars, gridDataStruct
      real, DIMENSION(nvars), INTENT(out) :: globalVarMin, globalVarMax

      real, allocatable :: varMin(:), varMax(:)
      real, dimension(:,:,:,:), pointer :: solnData

      integer :: i, j, k, n

      integer :: ierr
      integer, dimension(2,MDIM) :: blkLmts
      type(Grid_iterator_t) :: itor
      type(Grid_tile_t)     :: tileDesc

      nullify(solnData)

      if(nvars > 0) then
            allocate(varMin(nvars))
            allocate(varMax(nvars))

            ! start by finding the extrema locally on each processor
            varMin(:) = huge(varMin)
            varMax(:) = -huge(varMax)

            call Grid_getTileIterator(itor, LEAF, tiling=.FALSE.)
            do while (itor%isValid())
                  call itor%currentTile(tileDesc)

                  call tileDesc%getDataPtr(solnData, gridDataStruct)
                  blkLmts = tileDesc%limits !DEV: Add one for FACE-centered data?

                  select case(gridDataStruct)
                  case(CENTER)
                     do                k = blkLmts(1,KAXIS), blkLmts(2,KAXIS)
                              do       j = blkLmts(1,JAXIS), blkLmts(2,JAXIS)
                                    do i = blkLmts(1,IAXIS), blkLmts(2,IAXIS)
                                          do n = UNK_VARS_BEGIN, UNK_VARS_END
                                                if(io_unkToGlobal(n) > 0) then
                                                varMin(io_unkToGlobal(n)) = min(varMin(io_unkToGlobal(n)), solnData(n,i,j,k))
                                                varMax(io_unkToGlobal(n)) = max(varMax(io_unkToGlobal(n)), solnData(n,i,j,k))
                                                end if
                                          enddo
                                    enddo
                              enddo
                        enddo
                  case(SCRATCH, FACEX, FACEY, FACEZ)
                        do             k = blkLmts(1,KAXIS), blkLmts(2,KAXIS)
                              do       j = blkLmts(1,JAXIS), blkLmts(2,JAXIS)
                                    do i = blkLmts(1,IAXIS), blkLmts(2,IAXIS)
                                          do n = 1, nvars
                                                !if(.not. io_unkActive(n)) cycle
                                                varMin(n) = min(varMin(n), solnData(n,i,j,k))
                                                varMax(n) = max(varMax(n), solnData(n,i,j,k))
                                          enddo
                                    enddo
                              enddo
                        enddo
                  case default
                        call Driver_abort("io_getVarExtrema: dataStruct not implemented")
                  end select
                  
                  ! doing Grid_releaseBlkPtr expansion by hand, see: drift
                  call Driver_driftSetSrcLoc(__FILE__,__LINE__)
                  call tileDesc%releaseDataPtr(solnData, gridDataStruct)
                  
                  call itor%next()
            enddo
            call Grid_releaseTileIterator(itor)

            ! now do a global minimization or maximization
            call MPI_AllReduce(varMin, globalVarMin, nvars, FLASH_REAL, &
                  MPI_MIN, io_globalComm, ierr)

            call MPI_AllReduce(varMax, globalVarMax, nvars, FLASH_REAL, &
                  MPI_MAX, io_globalComm, ierr)
            
            deallocate(varMin)
            deallocate(varMax)
      endif
      return
end subroutine io_getVarExtrema

