!!****f* source/Grid/AMR/Amrex/Grid_getBlkCenterCoords
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
!!  Grid_getBlkCenterCoords
!!
!! SYNOPSIS
!!  Grid_getBlkCenterCoords(integer(IN) :: blockDesc
!!                          real(OUT)   :: blockCenter(MDIM))
!!  
!! DESCRIPTION 
!!   Gets the coordinates of the center of the block identified by
!!   blockDesc.  Returns the coordinates in an array blockCenter
!!
!! ARGUMENTS
!!  blockDesc - block_metadata_t of the block. for UG always 1
!!  blockCenter - returned array of size MDIM holding the blockCenter coords
!!
!! Example
!!   In 2 dimensions, if physical coordinates are ...
!!    
!!     ________________(0.5 1.0)
!!    |                |
!!    |                |
!!    |                |
!!    |                |
!!    |                |
!!    |                |
!!    |                |
!!    |_______________ |
!!  (-0.5, 0.0)
!!
!!  then the values returned in blockCenter are 
!!  blockCenter(IAXIS) = 0.0
!!  blockCenter(JAXIS) = 0.5
!!  blockCenter(KAXIS) = 0.0 since the dimension is not included  
!!
!!***

#include "constants.h"
#include "Simulation.h"

subroutine Grid_getBlkCenterCoords(blockDesc, blockCenter)

  use amrex_amrcore_module,  ONLY : amrex_geom
  use amrex_geometry_module, ONLY : amrex_problo

  use Grid_tile,        ONLY : Grid_tile_t

  implicit none

  type(Grid_tile_t), intent(IN)  :: blockDesc
  real,    intent(OUT) :: blockCenter(MDIM)

  real                 :: boundBox(LOW:HIGH, MDIM)

  integer :: i = 0

  ! DEV: FIXME How to manage matching amrex_real to FLASH real
  boundBox = 1.0d0
  associate(x0   => amrex_problo, &
            dx   => amrex_geom(blockDesc%level - 1)%dx, &
            lo   => blockDesc%limits(LOW,  :), &
            hi   => blockDesc%limits(HIGH, :))
    ! lo is 1-based cell-index of lower-left cell in block 
    ! hi is 1-based cell-index of upper-right cell in block
    blockCenter(1:NDIM) = x0(1:NDIM) + dx(1:NDIM) * (hi(1:NDIM)+lo(1:NDIM)-1) /2.0
  end associate
end subroutine Grid_getBlkCenterCoords
