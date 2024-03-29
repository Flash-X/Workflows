!!****if* source/Grid/GridMain/AMR/Amrex/Grid_addCoarseToFluxRegister
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
!!  Grid_addCoarseToFluxRegister
!!
!! SYNOPSIS
!!  call Grid_addCoarseToFluxRegister(integer(IN) :: coarse_level,
!!                          optional, logical(IN) :: isDensity(:),
!!                          optional, real(IN)    :: coefficient, 
!!                          optional, logical(IN) :: zeroFullRegister)
!!
!! DESCRIPTION 
!!  Each flux register is associated with a fine and a coarse level.  In normal
!!  use, client code could add flux data from both levels into the flux register
!!  for use with adjusting flux data on the coarse level.
!!
!!  This routine allows client code to request that the Grid unit add coarse data
!!  from the Grid unit's flux data structures to the contents of the associated
!!  flux registers.  This routine is clearly intended for use with AMR.  Note
!!  that the flux registers may choose to only store flux data that exists at 
!!  fine/coarse boundaries.
!!
!!  All data stored in the Grid unit's flux data structures as flux densities
!!  will automatically be transformed to flux before applying to the flux
!!  register.
!!
!!  Additionally, a multiple scale factor may be applied to all flux data before
!!  passing the data to the flux register.
!!
!!  It is assumed that before calling this routine, the client code has already
!!  written flux data to Grid's data structures using the Grid_getFluxPtr
!!  interface.
!!
!! ARGUMENTS
!!  coarse_level - the 1-based level index (1 is the coarsest level) indicating
!!                 which level's data should be added to the flux register as
!!                 coarse data.
!!  isDensity - a mask that identifies which physical flux quantities are
!!              actually stored in the Grid unit's flux data structures as
!!              flux densities.  If no mask is given, it is assumed that data
!!              is stored as flux.
!!  coefficient - a scaling parameter to apply to all flux data before applying
!!                the data to the flux register.
!!  zeroFullRegister - zero the current fine and coarse data in the register
!!                     before adding the indicated flux data to the register.
!!                     If this parameter is not given, then the current data is
!!                     not zeroed.
!!
!! SEE ALSO
!!   Grid_getFluxPtr/Grid_releaseFluxPtr
!!   Grid_zeroFluxRegister
!!   Grid_addCoarseToFluxRegister
!!   Grid_overwriteFluxes
!!
!!***

#include "Simulation.h"
#include "constants.h"

subroutine Grid_addCoarseToFluxRegister(coarse_level, isDensity, coefficient, &
                                        zeroFullRegister)
    use amrex_fort_module,    ONLY : wp => amrex_real
    use amrex_amrcore_module, ONLY : amrex_get_finest_level, &
                                     amrex_ref_ratio

    use Driver_interface,     ONLY : Driver_abort
    use Grid_interface,       ONLY : Grid_getGeometry
    use gr_physicalMultifabs, ONLY : flux_registers, &
                                     fluxes

    implicit none

    integer, intent(IN)           :: coarse_level
    logical, intent(IN), optional :: isDensity(:)
    real,    intent(IN), optional :: coefficient
    logical, intent(IN), optional :: zeroFullRegister

    integer  :: coarse
    integer  :: fine
    integer  :: geometry
    real(wp) :: coef

    if (NFLUXES < 1) then
        RETURN
    end if
 
    ! FLASH uses 1-based level index / AMReX uses 0-based index
    coarse = coarse_level - 1
    fine   = coarse_level

    ! The finest refinement level is never the coarse level of a flux register
    if ((coarse < 0) .OR. (coarse >= amrex_get_finest_level())) then
        call Driver_abort("[Grid_addCoarseToFluxRegister] Invalid level")
    end if

    if (present(coefficient)) then
        coef = coefficient
    else
        coef = 1.0_wp
    end if

    if (present(isDensity)) then
        call Driver_abort("[Grid_addFineToFluxRegister] isDensity not implemented")
    end if

    if (present(zeroFullRegister)) then
        if (zeroFullRegister) then
            call flux_registers(fine)%setval(0.0_wp)
        end if
    end if

    call Grid_getGeometry(geometry)

    select case (geometry)
    case (CARTESIAN)
      ! The scaling factor=1/r^(NDIM-1) used here assumes that the refinement
      ! ratio, r, between levels is always 2
      if (amrex_ref_ratio(coarse) /= 2) then
        call Driver_abort("[Grid_addFineToFluxRegister] refinement ratio not 2")
      end if

#if   NDIM == 2
        coef = coef * 0.5_wp
#elif NDIM == 3
        coef = coef * 0.25_wp
#endif

        ! Flux registers index is 0-based index of fine level
        ! DEV: TODO We should be able to use crseinit here instead of using the
        ! setval call above.
        call flux_registers(fine)%crseadd(fluxes(coarse, 1:NDIM), coef)
    case default
        call Driver_abort("[Grid_addFineToFluxRegister] Only works with Cartesian")
    end select
end subroutine Grid_addCoarseToFluxRegister

