!!****if* source/Grid/GridMain/gr_extendedGetCellCoords
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
!!  gr_extendedGetCellCoords
!!
!! SYNOPSIS
!!
!!  gr_extendedGetCellCoords(integer(IN) :: axis,
!!                      integer(IN):: blockID, 
!!                      integer(IN):: pe, 
!!                      integer(IN):: edge, 
!!                      logical(IN):: guardcell, 
!!                      real(OUT)  :: coordinates(size),
!!                      integer(IN):: size)
!!  
!!  
!! DESCRIPTION
!!
!!    This subroutine is an accessor function that gets the coordinates of
!!    the cells in a given block. This is a generalized variant of
!!    Grid_getCellCoords, for use within the Grid unit only:
!!    it can be called for blocks local to the executing processor or,
!!    at least in the Paramesh 4 implementations of the Grid unit, for
!!    remote blocks for which cached information is currently locally
!!    available.
!!
!!    The block about which information is requested is identified by
!!    a pair (blockID, pe). All other arguments are as for Grid_getCellCoords
!!    and are passed to Grid_getCellCoords if it is called by this routine.
!!    This is a generic implementation which always fails when (pe .NE. myPE),
!!    an implementation that does anything beyond the regular Grid_getCellCoords
!!    can be found in the Paramesh 4 implementation of the Grid unit.
!!
!!    Coordinates are retrieved one axis at a time, 
!!    meaning you can get the i, j, _or_ k coordinates with one call.  
!!    If you want all the coordinates, all axes, you
!!    need to call gr_extendedGetCellCoords 3 times, one for each axis.
!!    The code carries coordinates at cell centers as well as faces.
!!    It is possible to get coordinates for CENTER, only LEFT_EDGE,
!!    only RIGHT_EDGE or for all FACES along a dimension.
!!
!!
!!
!!
!! ARGUMENTS
!!            
!!   axis - specifies the integer index coordinates of the cells being retrieved.
!!          axis can have one of three different values, IAXIS, JAXIS or KAXIS 
!!          (defined in constants.h as 1,2 and 3)
!!
!!   blockID - integer block number
!!
!!   pe      - processor where block (or a cached copy of block info) resides
!!
!!   edge - integer value with one of four values, 
!!          LEFT_EDGE, RIGHT_EDGE, CENTER or FACES
!!          The edge argument specifies what side of the zone to get, 
!!          the CENTER point, the LEFT_EDGE  or the RIGHT_EDGE of the zone.
!!          FACES gets the left and right face of each cell, but since 
!!          two adjacent cells have a common face, there are only N+1
!!          unique values if N is the number of cells.
!!
!!   guardcell - logical input. If true coordinates for guardcells are returned
!!          along with the interior cells, if false, only the interior coordinates 
!!          are returned.
!!
!!          
!!   coordinates - The array holding the data returning the coordinate values
!!                 coordinates must be at least as big as "size" (see below)
!!           
!!   size - integer specifying the size of the coordinates array.
!!          if edge = CENTER/LEFT_EDGE/RIGHT_EDGE then
!!                If guardcell true then size =  interior cells + 2*guardcells
!!                otherwise size = number of interior cells
!!          If edge=FACES 
!!                If guardcell true then size =  interior cells + 2*guardcells+1
!!                otherwise size = number of interior cells+1
!!
!!               
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
!!   Grid_getCellCoords
!!
!!***

#ifdef DEBUG
#define DEBUG_GRID
#endif

#include "Simulation.h"
#include "constants.h"

subroutine gr_extendedGetCellCoords(axis, tileDesc, pe, edge, guardcell, coordinates, size)

  use Grid_data, ONLY : gr_meshMe
  use Grid_interface, ONLY : Grid_getCellCoords
  use Driver_interface, ONLY : Driver_abort
  use Grid_tile, ONLY : Grid_tile_t

  implicit none

  type(Grid_tile_t), intent(in) :: tileDesc
  integer, intent(in) :: axis, pe, edge
  integer, intent(in) :: size
  logical, intent(in) :: guardcell
  real,intent(out), dimension(size) :: coordinates

  integer :: lo(1:MDIM)
  integer :: hi(1:MDIM)

  lo(:) = tileDesc%limits(LOW,  :)
  hi(:) = tileDesc%limits(HIGH, :)
  if (guardcell) then
      lo(1:NDIM) = lo(1:NDIM) - NGUARD
      hi(1:NDIM) = hi(1:NDIM) + NGUARD
  end if

  if (pe.EQ.gr_meshMe) then
     call Grid_getCellCoords(axis, edge, tileDesc%level, lo, hi, coordinates)
  else
     call Driver_abort('Calling gr_extendedGetCellCoords for'// & 
             &      ' remote blocks is not supported in this Grid implementation.')
  endif

  return
end subroutine gr_extendedGetCellCoords





