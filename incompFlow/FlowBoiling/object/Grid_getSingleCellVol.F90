!!****if* source/Grid/GridMain/Grid_getSingleCellVol
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
!!  Grid_getSingleCellVol
!!
!! SYNOPSIS
!!
!!  Grid_getSingleCellVol(integer(IN) :: blockid,
!!                        integer(IN) :: beginCount,
!!                        integer(IN) :: point(MDIM), 
!!                        real(OUT)   :: cellVolume)
!!  
!! DESCRIPTION 
!!  
!!  Gets cell volumes for a single cell in a given block. 
!!
!!  
!! ARGUMENTS 
!!
!!  blockid - integer local blockid
!!
!!  beginCount : tells the routine where to start index counting.  beginCount can
!!               be set to INTERIOR or EXTERIOR.  If INTERIOR is specified,
!!               guardcell indices are not included and index 1 is the first interior cell. 
!!               If EXTERIOR is specified,
!!               the first index, 1, is the leftmost guardcell.  See example
!!               below for more explanation.  (For most of the FLASH architecture code,
!!               we use EXTERIOR.  Some physics routines, however, find it helpful 
!!               only to work on the internal parts of the blocks (without
!!               guardcells) and wish to keep loop indicies  
!!               going from 1 to NXB without having to worry about finding 
!!               the correct offset for the number of guardcells.) 
!!               (INTERIOR and EXTERIOR are defined in constants.h)
!! 
!!  point(MDIM):
!!           specifies the point to return
!!   
!!           point(1) = i
!!           point(2) = j
!!           point(3) = k
!!
!!           If a problem is only 2d, point(3) is ignored.  For 1d problems
!!           point(2) and point(3) are ignored.
!!
!!
!!  cellVolume - real value containing the cell volume
!!
!!
!! NOTES
!! 
!!  Current implementations of this interface assume that all cells in a 
!!  dimension of a block have the same grid spacing. The grid spacings used
!!  are the ones returned by Grid_getDeltas.
!!
!! SEE ALSO
!!
!!  Grid_getDeltas
!!  Grid_getSingleCellCoords
!!
!!***

#include "constants.h"
#include "Simulation.h"

subroutine Grid_getSingleCellVol(point, level, cellvolume)
  use Driver_interface, ONLY : Driver_abort
!  use Grid_interface,   ONLY : Grid_getDeltas, &
!                               Grid_getGeometry, &
!                               Grid_getSingleCellCoords

  implicit none

  integer, intent(IN)  :: point(MDIM)
  integer, intent(IN)  :: level
  real,    intent(OUT) :: cellvolume

  cellvolume = 0.0
  call Driver_abort("[Grid_getSingleCellVol] DEPRECATED")

!  integer :: geometry
!  real    :: del(1:MDIM)
!  real    :: centerCoords(1:MDIM)
!  real    :: leftCoords(1:MDIM)
!  real    :: rightCoords(1:MDIM)
! 
!  call Grid_getGeometry(geometry)
!  call Grid_getDeltas(level, del)
!
!  if (.NOT. ((geometry == CARTESIAN                  ) .OR. &
!             (geometry == CYLINDRICAL .AND. NDIM == 2))  ) then
!    cellvolume = 0.0
!    call Driver_abort("[Grid_getSingleCellVol] Not tested yet")
!  end if
!
!  select case (geometry)
!
!  case (CARTESIAN)
!     associate(dx => del(IAXIS), &
!               dy => del(JAXIS), &
!               dz => del(KAXIS))
!        if(NDIM == 1) then
!           cellvolume = dx
!        else if(NDIM == 2) then
!           cellvolume = dx * dy
!        else
!           cellvolume = dx * dy * dz
!        end if
!     end associate
!
!  case (POLAR)
!     call Grid_getSingleCellCoords(point, level, CENTER, centerCoords)
!
!     associate(dr   => del(IAXIS), &
!               dPhi => del(JAXIS), &
!               dz   => del(KAXIS), &
!               r    => ABS(centerCoords(IAXIS)))
!        if(NDIM == 1) then
!           cellvolume = 2.*PI * r * dr
!        else if(NDIM == 2) then
!           cellvolume = r * dr * dPhi
!        else
!           cellvolume = r * dr * dz * dPhi
!        end if
!     end associate
!
!  case (CYLINDRICAL)
!     call Grid_getSingleCellCoords(point, level, CENTER, centerCoords)
!
!     associate(dr   => del(IAXIS), &
!               dz   => del(JAXIS), &
!               dPhi => del(KAXIS), &
!               r    => ABS(centerCoords(IAXIS)))
!        if(NDIM == 1) then
!           cellvolume = 2.*PI * r * dr
!        else if(NDIM == 2) then
!           cellvolume = 2.*PI * r * dr * dz
!        else
!           cellvolume = r * dr * dz * dPhi
!        end if
!     end associate
!
!  case (SPHERICAL)
!     call Grid_getSingleCellCoords(point, level, LEFT_EDGE, leftCoords)
!     call Grid_getSingleCellCoords(point, level, RIGHT_EDGE, rightCoords)
!
!     associate(dr      => del(IAXIS), &
!               dTheta  => del(JAXIS), &
!               dPhi    => del(KAXIS), &
!               r_inner => ABS(leftCoords(IAXIS)), &
!               r_outer => ABS(rightCoords(IAXIS)), &
!               theta_L => leftCoords(JAXIS), &
!               theta_R => rightCoords(JAXIS))
!        ! This is equal to r_outer^3 - r_inner^3
!        cellvolume = dr * (r_inner * r_inner +  &
!                           r_inner * r_outer + &
!                           r_outer * r_outer)
!        if(NDIM == 1) then
!           cellvolume = cellvolume * 4.*PI/3.
!        else if(NDIM == 2) then
!           cellvolume = cellvolume * ( cos(theta_L) - cos(theta_R) ) * 2.*PI/3.
!        else
!           cellvolume = cellvolume * ( cos(theta_L) - cos(theta_R) ) * dPhi/3.
!        end if
!     end associate
!
!  end select

end subroutine Grid_getSingleCellVol

