!!****ih* source/Grid/GridMain/AMR/Amrex/block_1lev_iterator
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
!!  block_1lev_iterator
!!
!! DESCRIPTION
!!  A class that defines an iterator facade around the AMReX MFIter
!!  (amrex_mfiter) such that client code may use the iterator for sequentially
!!  accessing specific blocks or tiles in the domain that exist only at a 
!!  single, given refinement level. 
!!
!!  Note that this iterator is meant only for internal FLASH use with 
!!  block_iterator_t.  No other code should need to use this code directly.
!!
!! SEE ALSO
!!  block_iterator_t
!!
!!****

#include "FortranLangFeatures.fh"
#include "constants.h"
#define DEBUG_ITERATOR

module block_1lev_iterator

    use amrex_multifab_module, ONLY : amrex_multifab
    use amrex_multifab_module, ONLY : amrex_mfiter, &
                                      amrex_mfiter_build, &
                                      amrex_mfiter_destroy
    use iso_c_binding,         ONLY : c_associated
    implicit none

    private

    !!****ic* block_1lev_iterator/block_1lev_iterator_t
    !!
    !! NAME
    !!  block_1lev_iterator_t
    !!
    !! DESCRIPTION
    !!  For AMReX, this class is being used under the hood of the
    !!  block_iterator_t class and should not be used elsewhere.  As a result of
    !!  this restriction, for instance, there is no need to give access to
    !!  block_metadata_t structures.
    !!
    !!  Note that the value of level is specified using FLASH's 1-based level
    !!  indexing scheme.
    !!
    !!****
    type, public :: block_1lev_iterator_t
        type(amrex_mfiter),   private, pointer :: mfi      => NULL()
        type(amrex_multifab), private, pointer :: mf       => NULL()
        integer,              private          :: nodetype = LEAF
        integer,              private          :: level    = INVALID_LEVEL
        logical,              private          :: isValid  = .FALSE.
        integer,              private          :: finest_grid_level
        ! DEV: FIXME This dummy parameter has been placed into the class due to
        !      an internal compiler error with GNU Fortran 6.4.0.
        !      This workaround was found online in relation to the particular
        !      error message and happily worked (See Issue 93).
        integer,              allocatable      :: dummy
    contains
        procedure, public :: is_valid
        procedure, public :: next
        procedure, public :: grid_index
        procedure, public :: local_tile_index
        procedure, public :: tilebox
        procedure, public :: growntilebox
        procedure, public :: fabbox
        procedure, public :: destroy_iterator
    end type block_1lev_iterator_t

    interface block_1lev_iterator_t
        procedure :: init_iterator_mf
        procedure :: init_iterator
    end interface block_1lev_iterator_t

contains

    !!****im* block_1lev_iterator_t/block_1lev_iterator_t
    !!
    !! NAME
    !!  block_1lev_iterator_t
    !!
    !! SYNOPOSIS
    !!  itor = block_1lev_iterator_t(integer(IN)           :: nodetype,
    !!                               integer(IN)           :: level, 
    !!                               logical(IN), optional :: tiling)
    !!
    !! DESCRIPTION
    !!  Construct an iterator for walking across a specific subset of blocks or
    !!  tiles within the the given refinement level.  The iterator is already
    !!  set to the first matching block/tile.
    !!
    !! ARGUMENTS
    !!  nodetype - the class of blocks to iterate over.  Acceptable values are
    !!             LEAF and ALL_BLKS.
    !!  level    - iterate only over blocks/tiles located at this level of
    !!             refinement.  Note that the level value must be given with
    !!             respect to FLASH's 1-based level index scheme.
    !!  tiling   - an optional optimization hint.  If TRUE, then the iterator will
    !!             walk across all associated blocks on a tile-by-tile basis *if*
    !!             the implementation supports this feature.  If a value is not
    !!             given, is FALSE, or the implementation does not support tiling,
    !!             the iterator will iterate on a block-by-block basis.
    !!
    !! RETURN VALUE
    !!  The initialized iterator
    !!
    !! SEE ALSO
    !!  constants.h
    !!****
  function init_iterator_mf(nodetype, mf, level, tiling, tileSize) result(this)
    use amrex_multifab_module, ONLY : amrex_multifab
    use amrex_amrcore_module,  ONLY : amrex_get_finest_level

    type(block_1lev_iterator_t)              :: this
    integer,              intent(IN)         :: nodetype
    type(amrex_multifab), intent(IN), TARGET :: mf
    integer,              intent(IN)         :: level
    logical,              intent(IN)         :: tiling
    integer,              intent(IN)         :: tileSize(1:MDIM)

    integer :: finest_level

    ! level and finest_level are 1-based
    this%finest_grid_level = amrex_get_finest_level()
    finest_level = this%finest_grid_level + 1
    if (level > finest_level) then
#ifdef DEBUG_ITERATOR
       print*,"[init_iterator] INFO: skipping level",level," finest_level is",finest_level
#endif
       RETURN                 !Skip the rest of initialization, leaving isValid false.
    end if

    this%nodetype = nodetype
    this%level = level
 
    if (c_associated(mf%p)) then

       allocate(this%mfi)

    ! Initial iterator is not primed.  Advance to first compatible block.
       if (tiling) then
          !DEV: TODO Do we need to error check tileSize against block size
          ! or does AMReX do this already?
          call amrex_mfiter_build(this%mfi,mf,tileSize=tileSize)
       else
          call amrex_mfiter_build(this%mfi,mf,tiling=.FALSE.)
       end if
       this%mf => mf
!!$    print*,'block_1lev_iterator: init_iterator_mf  on this=',this%isValid,this%level,associated(this%mfi)
       this%isValid = .TRUE.
       call this%next()
    else
#ifdef DEBUG_ITERATOR
       print*,"[init_iterator] INFO: multifab mf is not valid, this level is",this%level
#endif
    end if
  end function init_iterator_mf

    function init_iterator(nodetype, level, tiling, tileSize, inactivePar) result(this)
      use Driver_interface,      ONLY : Driver_abort
      use gr_physicalMultifabs,  ONLY : unk
      use amrex_amrcore_module,  ONLY : amrex_get_finest_level

      integer, intent(IN)         :: nodetype
      integer, intent(IN)         :: level
      logical, intent(IN)         :: tiling
      integer, intent(IN)         :: tileSize(1:MDIM)
      logical, intent(IN)         :: inactivePar
      type(block_1lev_iterator_t) :: this

      integer :: finest_level

      this%finest_grid_level = amrex_get_finest_level() ! 0-based finest existing level
      finest_level = this%finest_grid_level + 1 ! level and finest_level are 1-based
      if (level > finest_level) then
#ifdef DEBUG_ITERATOR
         print*,"[init_iterator] INFO: skipping level",level," finest_level is",finest_level
#endif
         RETURN                 !Skip the rest of initialization, leaving isValid false.
      end if

      this%nodetype = nodetype
      this%level = level
      this%mf => unk(level-1)

      ! Don't permit repeated calls to init without intermediate destroy call
      if (associated(this%mfi)) then
        call Driver_abort("[init_iterator] Destroy iterator before initializing again")
      end if

      if (c_associated(this%mf%p)) then

         allocate(this%mfi)
         if (inactivePar) then
            !$omp parallel default(shared) num_threads(1)
            if (tiling) then
               call amrex_mfiter_build(this%mfi, this%mf, tileSize=tileSize)
            else
               call amrex_mfiter_build(this%mfi, this%mf, tiling=.FALSE.)
            end if
            !$omp end parallel
         else
            if (tiling) then
               ! DEV: TODO Do we need to error check tileSize against block size
               call amrex_mfiter_build(this%mfi, this%mf, tileSize=tileSize)
            else
               call amrex_mfiter_build(this%mfi, this%mf, tiling=.FALSE.)
            end if
         end if

         ! Set to True so that next() works
         this%isValid = .TRUE.

         ! Initial MFIter is not primed.  Advance to first compatible block.
         call this%next()
      else
#ifdef DEBUG_ITERATOR
         print*,"[init_iterator] INFO: unk(level-1) is not valid for level",level
#endif
      end if
    end function init_iterator

    !!****im* block_1lev_iterator_t/destroy_iterator
    !!
    !! destroy_iterator
    !!
    !! SYNPOSIS
    !!  itor%destroy_iterator
    !!
    !! DESCRIPTION
    !!  Clean-up block iterator and internal resources.  Note that this is not a
    !!  destructor and therefore must be called manually.
    !!
    !!****
    IMPURE_ELEMENTAL subroutine destroy_iterator(this)
      class(block_1lev_iterator_t), intent(INOUT) :: this

      if (associated(this%mfi)) then
        call amrex_mfiter_destroy(this%mfi)
        deallocate(this%mfi)
        nullify(this%mfi)
      end if

      nullify(this%mf)
      this%isValid = .FALSE.
    end subroutine destroy_iterator

    !!****m* block_1lev_iterator_t/is_valid
    !!
    !! NAME
    !!  is_valid
    !!
    !! SYNPOSIS
    !!  logical valid = itor%is_valid()
    !!
    !! DESCRIPTION
    !!  Determine if the iterator is currently set to a valid block/tile.
    !!
    !! RETURN VALUE 
    !!  True if iterator is currently set to a valid block/tile
    !!
    !!****
    function is_valid(this) result(ans)
        class(block_1lev_iterator_t), intent(IN) :: this
        logical :: ans

        ans = this%isValid
    end function is_valid

    !!****m* block_1lev_iterator_t/next
    !!
    !! NAME
    !!  next
    !!
    !! SYNPOSIS
    !!  call itor%next()
    !!
    !! DESCRIPTION
    !!  Advance the iterator to the next block/tile managed by process and
    !!  that meets the iterator constraints given at instantiation.
    !!
    !!****
    subroutine next(this)
        use amrex_box_module, ONLY : amrex_box
        use Driver_interface, ONLY : Driver_abort

        class(block_1lev_iterator_t), intent(INOUT) :: this

        type(amrex_box) :: bx
        logical         :: hasChildren

        if (this%isValid) then
           do
              this%isValid = this%mfi%next()
              if (.NOT. this%isValid) then
                 exit
              else
                 select case (this%nodetype)
                 case(ALL_BLKS)
                    exit
                 case(LEAF)
                    bx = this%mfi%tilebox()
                    hasChildren = boxIsCovered(bx, this%level-1, this%finest_grid_level)
                    if (.NOT.hasChildren) exit
                 case default
                    call Driver_abort("[block_1lev_iterator]: Unsupported nodetype")
                 end select
              end if
           end do
        else
           call Driver_abort("[block_1lev_iterator]: attempting next() on invalid!")
        end if

    contains

        logical function boxIsCovered(bx,lev,finest_level) result(covered)
          use amrex_boxarray_module, ONLY : amrex_boxarray
          use amrex_amrcore_module,  ONLY : amrex_ref_ratio, &
                                            amrex_get_boxarray

          !IMPORTANT: data in bx is changed on return!
          type(amrex_box), intent(INOUT) :: bx
          integer,         intent(IN)    :: lev
          integer,         intent(IN)    :: finest_level ! Passing this saves a function call.

          type(amrex_boxarray) :: fba
          integer :: rr

          ! Assume lev is 0-based
          if (lev .GE. finest_level) then
             covered = .FALSE.
          else
             fba = amrex_get_boxarray(lev+1)
             rr = amrex_ref_ratio(lev)

             ! Note: this modifies bx, do not use naively after this!
             call bx%refine(rr)
             covered = fba%intersects(bx)
          end if
        end function boxIsCovered

    end subroutine next

    !!****m* block_1lev_iterator_t/grid_index
    !!
    !! NAME
    !!  grid_index
    !!
    !! SYNPOSIS
    !!  idx = itor%grid_index()
    !!
    !! DESCRIPTION
    !!  Advance the iterator to the next block managed by process and that meets
    !!  the iterator constraints given at instantiation.
    !!
    !!****
    function grid_index(this) result(idx)
      class(block_1lev_iterator_t), intent(IN) :: this
      integer                                  :: idx

      idx = this%mfi%grid_index()
    end function grid_index

    !!****m* block_1lev_iterator_t/local_tile_index
    !!
    !! NAME
    !!  local_tile_index
    !!
    !! SYNPOSIS
    !!  idx = itor%local_tile_index()
    !!
    !! DESCRIPTION
    !!  Advance the iterator to the next block managed by process and that meets
    !!  the iterator constraints given at instantiation.
    !!
    !!****
    function local_tile_index(this) result(idx)
      class(block_1lev_iterator_t), intent(IN) :: this
      integer                                  :: idx

      idx = this%mfi%local_tile_index()
    end function local_tile_index

    !!****m* block_1lev_iterator_t/tilebox
    !!
    !! NAME
    !!  tilebox
    !!
    !! SYNPOSIS
    !!  box = itor%tilebox()
    !!
    !! DESCRIPTION
    !!  Obtain the box without guardcells of the block/tile currently
    !!  "loaded" into the iterator.
    !!
    !! RETURN VALUE
    !!  An AMReX box object.  The index space of the box is the index
    !!  space of the multifab used to construct the underlying MFIter.
    !!  The spatial indices of the box use AMReX's 0-based scheme.
    !!
    !!****
    function tilebox(this) result(bx)
      use amrex_box_module, ONLY : amrex_box

      class(block_1lev_iterator_t), intent(in) :: this
      type(amrex_box)                          :: bx

      bx = this%mfi%tilebox()
    end function tilebox

    !!****m* block_1lev_iterator_t/growntilebox
    !!
    !! NAME
    !!  growntilebox
    !!
    !! SYNPOSIS
    !!  box = itor%growntilebox()
    !!
    !! DESCRIPTION
    !!  Obtain the box with guardcells of the block/tile currently
    !!  "loaded" into the iterator.  For tiles, the guardcells are those
    !!  guardcells of the tile's parent block that are adjacent to the
    !!  tile.  In this sense, each guardcell of the parent block is associated
    !!  with only one tile.
    !!
    !! RETURN VALUE
    !!  An AMReX box object.  The index space of the box is the index
    !!  space of the multifab used to construct the underlying MFIter.
    !!  The spatial indices of the box use AMReX's 0-based scheme.
    !!
    !!****
    function growntilebox(this) result(bx)
      use amrex_box_module, ONLY : amrex_box

      class(block_1lev_iterator_t), intent(in) :: this
      type(amrex_box)                          :: bx

      bx = this%mfi%growntilebox()
    end function growntilebox

    !!****m* block_1lev_iterator_t/fabbox
    !!
    !! NAME
    !!  fabbox
    !!
    !! SYNPOSIS
    !!  box = itor%fabbox()
    !!
    !! DESCRIPTION
    !!  Obtain the box wth guardcells of the block/tile currently
    !!  "loaded" into the iterator.
    !!
    !! RETURN VALUE
    !!  An AMReX box object.  The index space of the box is the index
    !!  space of the multifab used to construct the underlying MFIter.
    !!  The spatial indices of the box use AMReX's 0-based scheme.
    !!
    !!****
    function fabbox(this) result(bx)
      use amrex_box_module, ONLY : amrex_box

      class(block_1lev_iterator_t), intent(in) :: this
      type(amrex_box)                          :: bx
      
      bx = this%mfi%fabbox()
    end function fabbox

end module block_1lev_iterator

