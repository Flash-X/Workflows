!!****if* source/Grid/GridMain/AMR/Amrex/gr_restrictAllLevels
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
!!  gr_restrictAllLevels
!!
!! SYNOPSIS
!!  call gr_restrictAllLevels(integer(IN) :: gridDataStruct, 
!!                            logical(IN) :: convertPtoC,
!!                            logical(IN) :: convertCtoP)
!!
!!  For each leaf block, average the leaf data associated with the given grid
!!  data structure type down to all ancestor blocks.
!!
!!  For performance reasons, this routine does not make any assumptions about
!!  whether the data is presently in primitive or conservative form.  Nor does
!!  it make assumptions about which form it should be left.
!!
!! DESCRIPTION 
!!
!! ARGUMENTS 
!!  gridDataStruct - integer constant that indicates which grid data structure 
!!                   variable's data to average.  Valid values are
!!                     CENTER             cell-centered data only
!!                     FACEX              X face-centered data only
!!                     FACEY              Y face-centered data only
!!                     FACEZ              Z face-centered data only
!!                     FACES              All face-centered data only
!!                     CENTER_FACES       cell-centered and all face-centered
!! convertPtoC - if this value is true, then all primitive form quantities on 
!!               all leaf blocks will be converted to conservative form before 
!!               averaging.
!! convertCtoP - if this value is true, then all primitive form quantities will
!!               be reverted back to primitive form after averaging.
!!  
!!***

#include "Simulation.h"
#include "constants.h"

subroutine gr_restrictAllLevels(gridDataStruct, convertPtoC, convertCtoP)
  use amrex_amrcore_module,      ONLY : amrex_get_finest_level, &
                                        amrex_geom, &
                                        amrex_ref_ratio
  use amrex_multifabutil_module, ONLY : amrex_average_down

  use Grid_interface,            ONLY : Grid_getTileIterator, &
                                        Grid_releaseTileIterator
  use gr_amrexInterface,         ONLY : gr_primitiveToConserve, &
                                        gr_conserveToPrimitive
  use Grid_iterator,             ONLY : Grid_iterator_t
  use Grid_tile,                 ONLY : Grid_tile_t
  use gr_physicalMultifabs,      ONLY : unk, &
                                        facevarx, facevary, facevarz
  use Driver_interface,          ONLY : Driver_abort

  implicit none

  integer, intent(IN) :: gridDataStruct
  logical, intent(IN) :: convertPtoC
  logical, intent(IN) :: convertCtoP

  integer :: lev
  integer :: finest_level

  type(Grid_iterator_t) :: itor
  type(Grid_tile_t)     :: tileDesc

  real, pointer :: solnData(:,:,:,:)

  nullify(solnData)

  if (       (gridDataStruct /= CENTER) .AND. (gridDataStruct /= CENTER_FACES) &
       .AND. (gridDataStruct /= FACES)  .AND. (gridDataStruct /= FACEX) &
       .AND. (gridDataStruct /= FACEY)  .AND. (gridDataStruct /= FACEZ)) then
     write(*,*) "Unsupported gridDataStruct ", gridDataStruct 
     call Driver_abort("[gr_restrictAllLevels]: Unsupported gridDataStruct")
  end if

  ! Work in AMReX 0-based level indexing
  finest_level = amrex_get_finest_level()

  !!!!! CELL-CENTERED DATA
  if ((gridDataStruct == CENTER) .OR. (gridDataStruct == CENTER_FACES)) then

    ! Convert primitive form to conservative form on leaves only as
    ! averaging will propagate conservative form down to ancestors
    if (convertPtoC) then
      call Grid_getTileIterator(itor, LEAF, tiling=.TRUE.)
      do while (itor%isValid())
        call itor%currentTile(tileDesc)
        call tileDesc%getDataPtr(solnData, CENTER)
        call gr_primitiveToConserve(tileDesc%Limits(LOW,  :), &
                                    tileDesc%Limits(HIGH, :), &
                                    solnData, &
                                    tileDesc%blkLimitsGC(LOW,  :), &
                                    tileDesc%blkLimitsGC(HIGH, :), &
                                    NUNK_VARS, &
                                    UNK_VARS_BEGIN, NUNK_VARS)


        call tileDesc%releaseDataPtr(solnData, CENTER)
        call itor%next()
      end do
      call Grid_releaseTileIterator(itor)
    end if

    ! Average from finest down to coarsest
    do lev = finest_level, 1, -1
        call amrex_average_down(unk(lev  ), &
                                unk(lev-1), &
                                amrex_geom(lev  ), &
                                amrex_geom(lev-1), &
                                UNK_VARS_BEGIN, NUNK_VARS, &
                                amrex_ref_ratio(lev-1))
    end do 

    ! Revert conservative form back to primitive form on all blocks
    if (convertCtoP) then
      call Grid_getTileIterator(itor, ALL_BLKS, tiling=.TRUE.)
      do while (itor%isValid())
        call itor%currentTile(tileDesc)
        call tileDesc%getDataPtr(solnData, CENTER)
        call gr_conserveToPrimitive(tileDesc%Limits(LOW,  :), &
                                    tileDesc%Limits(HIGH, :), &
                                    solnData, &
                                    tileDesc%blkLimitsGC(LOW,  :), &
                                    tileDesc%blkLimitsGC(HIGH, :), &
                                    NUNK_VARS, &
                                    UNK_VARS_BEGIN, NUNK_VARS)


        call tileDesc%releaseDataPtr(solnData, CENTER)
        call itor%next()
      end do
      call Grid_releaseTileIterator(itor)
    end if

  end if

#if NFACE_VARS > 0
  !!!!! FACE-CENTERED DATA
  if (     (gridDataStruct == CENTER_FACES) &
      .OR. (gridDataStruct == FACES) .OR. (gridDataStruct == FACEX)) then
    do lev = finest_level, 1, -1
        call amrex_average_down(facevarx(lev  ), &
                                facevarx(lev-1), &
                                amrex_geom(lev  ), &
                                amrex_geom(lev-1), &
                                1, NFACE_VARS, &
                                amrex_ref_ratio(lev-1))
    end do 
  end if
#if NDIM >= 2
  if (     (gridDataStruct == CENTER_FACES) &
      .OR. (gridDataStruct == FACES) .OR. (gridDataStruct == FACEY)) then
    do lev = finest_level, 1, -1
        call amrex_average_down(facevary(lev  ), &
                                facevary(lev-1), &
                                amrex_geom(lev  ), &
                                amrex_geom(lev-1), &
                                1, NFACE_VARS, &
                                amrex_ref_ratio(lev-1))
    end do 
  end if
#endif
#if NDIM == 3
  if (     (gridDataStruct == CENTER_FACES) &
      .OR. (gridDataStruct == FACES) .OR. (gridDataStruct == FACEZ)) then
    do lev = finest_level, 1, -1
        call amrex_average_down(facevarz(lev  ), &
                                facevarz(lev-1), &
                                amrex_geom(lev  ), &
                                amrex_geom(lev-1), &
                                1, NFACE_VARS, &
                                amrex_ref_ratio(lev-1))
    end do 
  end if
#endif
#else
  if (     (gridDataStruct == FACES) .OR. (gridDataStruct == FACEX) &
      .OR. (gridDataStruct == FACEY) .OR. (gridDataStruct == FACEZ)) then
    call Driver_abort("[gr_restrictAllLevels] No face data to work with")
  end if
#endif

end subroutine gr_restrictAllLevels

