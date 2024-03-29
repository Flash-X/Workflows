!!****f* source/physics/Hydro/Hydro_computeDt
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
!!  Hydro_computeDt
!!
!!
!! SYNOPSIS
!!
!!  Hydro_computeDt(Grid_tile_t(IN) :: tileDesc,
!!                  real(IN) ::  x(:), 
!!                  real(IN) :: dx(:), 
!!                  real(IN) :: uxgrid(:),
!!                  real(IN) :: y(:), 
!!                  real(IN) :: dy(:), 
!!                  real(IN) :: uygrid(:), 
!!                  real(IN) ::  z(:), 
!!                  real(IN) :: dz(:), 
!!                  real(IN) :: uzgrid(:), 
!!                  real,pointer ::  solnData(:,:,:,:),   
!!                  real,(INOUT) ::   dtCheck, 
!!                  integer(INOUT) :: dtMinLoc(:),
!!                  real(INOUT), optional :: extraInfo)
!!
!! DESCRIPTION
!!
!!  Computes the timestep limiter for the hydrodynamical solver.  For pure
!!  hydrodynamics, the Courant-Fredrichs-Lewy criterion is used.  The sound
!!  speed is computed and together with the velocities, is used to constrain
!!  the timestep such that no information can propagate more than one zone
!!  per timestep.
!!
!!
!! ARGUMENTS
!!
!!  tileDesc -- meta-information about the tile/block
!!  x, y, z --      coordinates
!!  dx, dy, dz --   deltas in each {x, y z} directions
!!  uxgrid, uygrid, uzgrid-- velocity of grid expansion in {x, y z} directions
!!  solnData --     the physical, solution data from grid
!!  dtCheck --     variable to hold timestep constraint
!!  dtMinLoc(5) -- array to hold location of cell responsible for minimum dt:
!!                 dtMinLoc(1) = i index
!!                 dtMinLoc(2) = j index
!!                 dtMinLoc(3) = k index
!!                 dtMinLoc(4) = blockID
!!                 dtMinLoc(5) = hy_meshMe
!!  extraInfo   -  Driver_computeDt can provide extra info to the caller
!!                 using this argument.
!!
!!***

subroutine Hydro_computeDt (tileDesc,  &
                           x, dx, uxgrid, &
                           y, dy, uygrid, &
                           z, dz, uzgrid, &
                           blkLimits,blkLimitsGC,        &
                           solnData,   &
                           dtCheck, dtMinLoc, &
                           extraInfo)
  
       use Grid_tile, ONLY : Grid_tile_t
  
#include "Simulation.h"
#include "constants.h"

  implicit none


  type(Grid_tile_t), intent(IN) :: tileDesc
  integer, intent(IN),dimension(2,MDIM)::blkLimits,blkLimitsGC
  real,INTENT(INOUT)    :: dtCheck
  integer,INTENT(INOUT)    :: dtMinLoc(5)
  real, pointer, dimension(:,:,:,:) :: solnData
  real, dimension(blkLimitsGC(LOW,IAXIS):blkLimitsGC(HIGH,IAXIS)), intent(IN) :: x, dx, uxgrid
  real, dimension(blkLimitsGC(LOW,JAXIS):blkLimitsGC(HIGH,JAXIS)), intent(IN) :: y, dy, uygrid
  real, dimension(blkLimitsGC(LOW,KAXIS):blkLimitsGC(HIGH,KAXIS)), intent(IN) :: z, dz, uzgrid
  real, OPTIONAL,intent(INOUT) :: extraInfo

  return
end subroutine Hydro_computeDt

