!!****f* source/Grid/Grid_bcApplyToRegionMixedGds
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
!!  Grid_bcApplyToRegionMixedGds
!!
!! SYNOPSIS
!!
!!  call Grid_bcApplyToRegionMixedGds(integer(IN)          :: bcType,
!!                                    integer(IN)          :: gridDataStruct,
!!                                    integer(IN)          :: level,
!!                                    integer(IN)          :: guard,
!!                                    integer(IN)          :: bcDir,
!!                                    integer(IN)          :: face,
!!                            POINTER,real(INOUT)          :: regionDataC(:,:,:,:),
!!                            POINTER,real(INOUT)          :: regionDataFN(:,:,:,:),
!!                            POINTER,real(INOUT)          :: regionDataFT1(:,:,:,:),
!!                            POINTER,real(INOUT)          :: regionDataFT2(:,:,:,:),
!!                                    integer(IN)          :: regionSizeC(REGION_DIM),
!!                                    logical(INOUT)       :: apply,
!!                                    integer(IN)          :: secondDir,
!!                                    integer(IN)          :: thirdDir,
!!                                    integer(IN)          :: endPoints(LOW:HIGH,MDIM),
!!                                    logical(IN)          :: rightHanded,
!!                           OPTIONAL,integer(IN)          :: idest)
!!
!!
!!
!! DESCRIPTION 
!!
!!  Applies the boundary conditions to the specified data structure.
!!  The routine is handed a region that has been extracted from the
!!  data structure, on which it should apply the boundary conditions. 
!!  The direction along which the BC are to be applied is always the first
!!  dimension in the given region, and the last dimension contains the
!!  the variables in the data structure. The middle two dimension contain
!!  the size of the region along the two dimensions of the physical grid
!!  that are not having the BC applied.
!!
!!  This routine applies the boundary conditions on a given face (lowerface
!!  or upperface) normal to a given BC direction bcDir, by using and setting
!!  values for all or some variables in the gridDataStruct.
!! 
!!     If (face=LOW)  
!!       regionData(1:guard,:,:,variables) =  boundary values
!!     If (face=HIGH) 
!!       regionData(regionSize(BC_DIR)-guard+1:regionSize(BC_DIR),:,:,variables) =  boundary values
!!
!!  One reason why information about direction and variable is
!!  included in this interface is because velocities need to be
!!  treated specially for REFLECTING boundary conditions. if
!!  bcDir=IAXIS, then the variable VELX_VAR is treated differently,
!!  same with VELY_VAR if bcDir=JAXIS and VELZ_VAR if
!!  bcDir=KAXIS. All supported mesh packages extract the vector passed
!!  in through the argument "dataRow" from the appropriated blocks,
!!  and send it to this routine for boundary calculation. The
!!  PERIODIC boundary is calculated by default when the blocks are
!!  exchanging data with each other.
!!  One possible implementation of this interface passes handling of all other
!!  boundary condition types on to calls of the old style Grid_applyBCEdge,
!!  which is called for each of the variables in turn.  However, this implementation
!!  does not do that; it implements the handling of simple boundary condition types
!!  directly by modifying the regionData where it represents guard cells.
!!
!!  This routine supports simple boundary conditions that are applied strictly
!!  directionally, and have no need for other grid information such as the coordinates etc.
!!  Additional dummy arguments blockHandle, secondDir, thirdDir, endPoints, and blkLimitsGC
!!  are not needed for these simple kinds of BCs, but can be used for BC types that do
!!  need coordinate information etc.
!!  Currently supported boundary conditions include "OUTFLOW", "REFLECTING" and "DIODE".
!!  The "PERIODIC" boundary conditions are automatically applied in the process of filling
!!  the guard cells all over the domain, and therefore do not need to call this routine.
!!
!!  If the user wishes to apply different boundary conditions, they can either
!!  use the interface Grid_bcApplyToRegionSpecialized, or make a copy of this
!!  routine in their simulation directory and customize it.
!!
!!
!! ARGUMENTS 
!!
!!  bcType - the type of boundary condition being applied.
!!  gridDataStruct - the Grid dataStructure, should be given as
!!                   one of the constants CENTER, FACEX, FACEY, FACEZ
!!                   (or, with some Grid implementations, WORK).
!!  level - the 1-based refinement level on which the regionData is defined
!!  guard -    number of guard cells
!!  bcDir  - the dimension along which to apply boundary conditions,
!!          can take values of IAXIS, JAXIS and KAXIS
!!  face    -  can take values LOW and HIGH, defined in constants.h,
!!             to indicate whether to apply boundary on lowerface or 
!!             upperface
!!  regionData     : the extracted region from a block of permanent storage of the 
!!                   specified data structure. Its size is given by regionSize.
!!  regionSize     : regionSize(BC_DIR) contains the size of each row of data
!!                   in the regionData array.  For the common case of guard=4,
!!                   regionSize(BC_DIR) will be 8 for cell-centered data structures
!!                   (e.g., when gridDataStruct=CENTER) and either 8 or 9 for face-
!!                   centered data, depending on the direction given by bcDir.
!!                   regionSize(SECOND_DIR) contains the number of rows along the second
!!                   direction, and regionSize(THIRD_DIR) has the number of rows
!!                   along the third direction. regionSize(GRID_DATASTRUCT) contains the
!!                   number of variables in the data structure.
!!  apply - Do it.
!!          !DEV: This dummy arg is quite pointless and should go away. - KW
!!  secondDir,thirdDir -   Second and third coordinate directions.
!!                         These are the transverse directions perpendicular to
!!                         the sweep direction.
!!                         This is not needed for simple boundary condition types
!!                         such as REFLECTIVE or OUTFLOW, It is provided for
!!                         convenience so that more complex boundary condition
!!                         can make use of it.
!!                         The values are currently fully determined by the sweep
!!                         direction bcDir as follows:
!!                          bcDir   |    secondDir       thirdDir
!!                          ------------------------------------------
!!                          IAXIS   |    JAXIS             KAXIS
!!                          JAXIS   |    IAXIS             KAXIS
!!                          KAXIS   |    IAXIS             JAXIS
!!
!!  endPoints - starting and endpoints of the region of interest.
!!              See also NOTE (1) below.
!!
!!  idest - Only meaningful with PARAMESH 3 or later.  The argument indicates which slot
!!          in its one-block storage space buffers ("data_1blk.fh") PARAMESH is in the
!!          process of filling.
!!          The following applies when guard cells are filled as part of regular
!!          Grid_fillGuardCells processing (or, in NO_PERMANENT_GUARDCELLS mode,
!!          in order to satisfy a Grid_getBlkPtr request): The value is 1 if guard cells
!!          are being filled in the buffer slot in UNK1 and/or FACEVAR{X,Y,Z}1 or WORK1
!!          that will end up being copied to permanent block data storage (UNK and/or
!!          FACEVAR{X,Y,Z} or WORK, respectively) and/or returned to the user.
!!          The value is 2 if guard cells are being filled in the alternate slot in
!!          the course of assembling data to serve as input for coarse-to-fine
!!          interpolation.
!!          When guard cells are being filled in order to provide input data for
!!          coarse-to-fine interpolation as part of amr_prolong processing (which
!!          is what happens when Grid_updateRefinement is called for an AMR Grid),
!!          the value is always 1.
!!
!!          In other words, you nearly always want to ignore this optional
!!          argument.  As of FLASH 3.1, it is only used internally within the
!!          Grid unit by a Multigrid GridSolver implementation.
!!
!!  NOTES 
!!
!!   (1)      NOTE that the second index of the endPoints and
!!            blkLimitsGC arrays count the (IAXIS, JAXIS, KAXIS)
!!            directions in the usual order, not permuted as in
!!            regionSize.
!!
!!   (2)      The preprocessor symbols appearing in this description
!!            as well as in the dummy argument declarations (i.e.,
!!            all the all-caps token (other than IN and OUT)) are
!!            defined in constants.h.
!!
!!   (3)      This routine is common to all the mesh packages supported.
!!            The mesh packages extract the small arrays relevant to
!!            boundary condition calculations from their Grid data 
!!            structures. 
!!
!!   (4)      If users wish to apply a different boundary condition, 
!!            they should look at routine Grid_bcApplyToRegionSpecialized.
!!            Customization can occur by creating a nontrivial implementation
!!            of Grid_bcApplyToRegionSpecialized in the Simulation unit (preferred)
!!            or by replacing the default implementation of  Grid_bcApplyToRegion.
!!
!!    2013       Initial Grid_bcApplyToRegionMixedGds interface - Klaus Weide
!!
!!***

#include "constants.h"
#include "Simulation.h"

subroutine Grid_bcApplyToRegionMixedGds(bcType,gridDataStruct,level,&
          guard,bcDir,face,&
          regionDataC,regionDataFN,regionDataFT1,regionDataFT2,&
          regionSizeC,&
          apply,&
          secondDir,thirdDir,endPoints,rightHanded, idest)

  implicit none
  
  integer, intent(IN) :: bcType,bcDir,face,guard,gridDataStruct,level
  integer,dimension(REGION_DIM),intent(IN) :: regionSizeC
  real,pointer,dimension(:,:,:,:) :: regionDataFN, regionDataFT1, regionDataFT2, regionDataC
  logical, intent(INOUT) :: apply
  integer,intent(IN) :: secondDir,thirdDir
  integer,intent(IN),dimension(LOW:HIGH,MDIM) :: endPoints
  logical, intent(IN) :: rightHanded
  integer,intent(IN),OPTIONAL:: idest

  !apply = .FALSE.
end subroutine Grid_bcApplyToRegionMixedGds

