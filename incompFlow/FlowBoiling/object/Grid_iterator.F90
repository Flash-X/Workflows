!!****ih* source/Grid/GridMain/AMR/Amrex/Grid_iterator
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
!!  Grid_iterator
!!
!! DESCRIPTION
!!  A class that defines a full-featured iterator for sequentially accessing
!!  specific blocks or tiles in the physical domain.  At initialization, the
!!  client code informs the initialization routine what blocks/tiles need to
!!  be accessed by the client code via the iterator.
!!
!!  Please refer to the documentation of Grid_getTileIterator for more
!!  information regarding iterator initialization.
!!
!! EXAMPLE
!!  The following example demonstrates looping over all blocks defined on
!!  the coarsest level.
!!
!!  type(Grid_tile_t) :: tileDesc
!!
!!  call Grid_getTileIterator(itor, ALL_BLKS, level=1)
!!  do while (itor%isValid())
!!    call itor%currentTile(tileDesc)
!!
!!    call tileDesc%getDataPtr(solnData, CENTER)
!!                          ...
!!      work with cell-centered data of current block
!!                          ... 
!!    call tileDesc%releaseDataPtr(solnData, CENTER)
!!
!!    call itor%next()
!!  end do
!!  call Grid_releaseTileIterator(itor)
!!
!! SEE ALSO
!!  Grid_getTileIterator
!!  Grid_releaseTileIterator
!!  Grid_tile_t
!!
!!****

#include "AMReX_Config.H"
#include "FortranLangFeatures.fh"
#include "constants.h"
#include "Simulation.h"

module Grid_iterator
    use block_1lev_iterator, ONLY : block_1lev_iterator_t

    implicit none

    private

    public :: build_iterator, destroy_iterator

    !!****ic* Grid_iterator/Grid_iterator_t
    !!
    !! NAME
    !!  Grid_iterator_t
    !!
    !! DESCRIPTION
    !!  This class maintains a set of single-level iterators, which are used
    !!  internally to walk blocks/tiles.
    !!
    !!  NOTE: The three level integers as well as the index of li use FLASH's
    !!        1-based level indexing.
    !!****
    type, public :: Grid_iterator_t
        type(block_1lev_iterator_t), private, pointer :: li(:)       => null()
        integer,                     private          :: first_level = INVALID_LEVEL
        integer,                     private          :: last_level  = INVALID_LEVEL
        integer,                     private          :: level       = INVALID_LEVEL
        logical,                     private          :: is_valid    = .FALSE.
    contains
        procedure, public :: isValid
        procedure, public :: next
        procedure, public :: currentTile
    end type Grid_iterator_t

    interface build_iterator
        procedure :: init_iterator
    end interface build_iterator

contains

    !!****im* Grid_iterator_t/build_iterator
    !!
    !! NAME
    !!  build_iterator
    !!
    !! SYNOPOSIS
    !!  build_iterator(Grid_iterator_t(OUT) :: itor,
    !!                 integer(IN)           :: nodetype,
    !!                 integer(IN), optional :: level,
    !!                 logical(IN), optional :: tiling,
    !!                 integer(IN), optional :: nthreads)
    !!
    !! DESCRIPTION
    !!  Construct an iterator for walking across a specific subset of blocks or
    !!  tiles within the current AMReX octree structure.  The iterator is already
    !!  set to the first matching block/tile.
    !!
    !!  NOTE: Prefer iterator acquisition/destruction via Grid unit local 
    !!        interface --- Grid_getTileIterator/Grid_releaseTileIterator.
    !!
    !! ARGUMENTS
    !!  itor     - the constructed iterator
    !!  nodetype - the class of blocks to iterate over (e.g. LEAF, ACTIVE_BLKS).
    !!             Refer to the documentation for the AMReX version of
    !!             Grid_getTileIterator for more information.
    !!  level    - iterate only over all blocks/tiles of the correct nodetype
    !!             that are located at this level of refinement.  Note that the
    !!             level value must be given with respect to FLASH's 1-based
    !!             level index scheme.  If no level value is given, then
    !!             iteration is not restricted to any level.
    !!             A level value of UNSPEC_LEVEL is equivalent to omitting
    !!             this optional argument.
    !!  tiling   - an optional optimization hint.  If TRUE, then the iterator will
    !!             walk across all associated blocks on a tile-by-tile basis *if*
    !!             the implementation supports this feature.  If a value is not
    !!             given, is FALSE, or the implementation does not support tiling,
    !!             the iterator will iterate on a block-by-block basis.
    !!  nthreads - an optional argument that may affect division of the iteration
    !!             space in an active OpenMP parallel region.
    !!             In the present implementation, this has to be equal to the
    !!             value returned by omp_get_num_threads() if OpenMP is active.
    !!
    !!****
    subroutine init_iterator(itor, nodetype, level, tiling, tileSize, nthreads)
      use Logfile_interface, ONLY : Logfile_stamp
      use Driver_interface, ONLY : Driver_abort
      use amrex_amrcore_module, ONLY : amrex_get_finest_level
      use Grid_data, ONLY: gr_envOmpNumThreads
      !$ use omp_lib

      type(Grid_iterator_t), intent(OUT) :: itor
      integer,               intent(IN)  :: nodetype
      integer,               intent(IN)  :: level
      logical,               intent(IN)  :: tiling
      integer,               intent(IN)  :: tileSize(1:MDIM)
      integer,               intent(IN), optional :: nthreads

      integer :: lev
      integer :: finest_level
      logical :: is_lev_valid
      integer :: myNthreads, theirNthreads
      logical :: inactivePar

      inactivePar = .FALSE.

#ifdef _OPENMP
      myNthreads = omp_get_num_threads()
#   ifdef AMREX_USE_OMP
         theirNthreads = myNthreads
#   else
         theirNthreads = 1
#   endif
#else
      myNthreads = 1
#   ifdef AMREX_USE_OMP
         if (gr_envOmpNumThreads > 0) then
            theirNthreads = gr_envOmpNumThreads
         else
            theirNthreads = -999
         end if
#   else
         theirNthreads = 1
#   endif
#endif

      if (present(nthreads)) myNthreads = nthreads

      if (myNthreads .NE. theirNthreads) then
         if (myNthreads == 1 .AND. theirNthreads == -999) then
            call Logfile_stamp('Maybe you should set environment variable OMP_NUM_THREADS=1.')
            call Driver_abort('The AMReX library supports OpenMP, so FLASH should be configured for threading!')
#ifdef _OPENMP
         else if (myNthreads == 1) then
            inactivePar = .TRUE.
#endif
         else
            call Driver_abort('Grid_iterator: nthreads value not supported.')
         end if
      end if

      finest_level = amrex_get_finest_level() + 1

      associate(first => itor%first_level, &
                last  => itor%last_level)
        if (level .NE. UNSPEC_LEVEL) then
         ! Construct do nothing iterator if no blocks on level
           if (level > finest_level) then
              itor%is_valid = .FALSE.
              RETURN
           end if

           first = level
           last = level
        else
           first = 1
           last = finest_level
        end if
        itor%level = first
 
        allocate( itor%li(first : last) )

        do lev=first, last
            itor%li(lev) = block_1lev_iterator_t(nodetype, lev, &
                                                 tiling=tiling, &
                                                 tileSize=tileSize, &
                                                 inactivePar=inactivePar)
            is_lev_valid = itor%li(lev)%is_valid()
            if (is_lev_valid .AND. .NOT. itor%is_valid) then
               itor%is_valid = .TRUE.
               itor%level   = lev
            end if
        end do
      end associate
    end subroutine init_iterator

    !!****im* Grid_iterator_t/destroy_iterator
    !!
    !! NAME
    !!  destroy_iterator
    !!
    !! SYNPOSIS
    !!  Destroy given iterator
    !!
    !! DESCRIPTION
    !!  Clean-up block interator object at destruction
    !!
    !!****
    IMPURE_ELEMENTAL subroutine destroy_iterator(itor)
      type (Grid_iterator_t), intent(INOUT) :: itor

      integer :: lev

      if (associated(itor%li)) then
         do lev = itor%first_level, itor%last_level
            call itor%li(lev)%destroy_iterator()
         end do

         deallocate(itor%li)
         nullify(itor%li)
      end if

      itor%is_valid = .FALSE.
    end subroutine destroy_iterator

    !!****m* Grid_iterator_t/isValid
    !!
    !! NAME
    !!  isValid
    !!
    !! SYNPOSIS
    !!  logical valid = itor%isValid()
    !!
    !! DESCRIPTION
    !!  Determine if the iterator is currently set to a valid block/tile.
    !!
    !! RETURN VALUE 
    !!  True if iterator is currently set to a valid block/tile.
    !!
    !!****
    function isValid(this)
        class(Grid_iterator_t), intent(IN) :: this
        logical :: isValid

        isValid = this%is_valid
    end function isValid

    !!****m* Grid_iterator_t/next
    !!
    !! NAME
    !!  next
    !!
    !! SYNPOSIS
    !!  call itor%next()
    !!
    !! DESCRIPTION
    !!  Advance the iterator to the next block/tile managed by process and that meets
    !!  the iterator constraints given at instantiation.
    !!
    !!****
    subroutine next(this)
        class(Grid_iterator_t), intent(INOUT) :: this

        logical :: is_li_valid

        associate(lev => this%level)
            call this%li( lev )%next()
            is_li_valid = this%li( lev )%is_valid()

            ! Search for next allowable level that has blocks meeting our
            ! criteria
            do while ((lev .LT. this%last_level) .AND. (.NOT. is_li_valid))
               lev = lev + 1
               is_li_valid = this%li( lev )%is_valid()
            end do

            this%is_valid = is_li_valid
        end associate
    end subroutine next

    !!****m* Grid_iterator_t/currentTile
    !!
    !! NAME
    !!  currentTile 
    !!
    !! SYNPOSIS
    !!  call itor%currentTile(Grid_tile_t(OUT) : block)
    !!
    !! DESCRIPTION
    !!  Obtain meta data that characterizes the block/tile currently set in the
    !!  iterator.
    !!
    !!****
    subroutine currentTile(this, tileDesc)
        use amrex_box_module, ONLY : amrex_box
        use Grid_tile,       ONLY : Grid_tile_t

        class(Grid_iterator_t), intent(IN)  :: this
        type(Grid_tile_t),      intent(OUT) :: tileDesc

        type(amrex_box) :: box

        tileDesc%level      = this%level
        tileDesc%grid_index = this%li( this%level )%grid_index()
        tileDesc%tile_index = this%li( this%level )%local_tile_index()

        ! FLASH uses 1-based spatial indices / AMReX uses 0-based
        box = this%li( this%level )%tilebox()
        tileDesc%limits(:, :) = 1
        tileDesc%limits(LOW,  1:NDIM) = box%lo(1:NDIM) + 1
        tileDesc%limits(HIGH, 1:NDIM) = box%hi(1:NDIM) + 1

        box = this%li( this%level )%growntilebox()
        tileDesc%grownLimits(:, :) = 1
        tileDesc%grownLimits(LOW,  1:NDIM) = box%lo(1:NDIM) + 1
        tileDesc%grownLimits(HIGH, 1:NDIM) = box%hi(1:NDIM) + 1

        box = this%li( this%level )%fabbox()
        tileDesc%blkLimitsGC(:, :) = 1
        tileDesc%blkLimitsGC(LOW,  1:NDIM) = box%lo(1:NDIM) + 1
        tileDesc%blkLimitsGC(HIGH, 1:NDIM) = box%hi(1:NDIM) + 1
    end subroutine currentTile 
 
end module Grid_iterator

