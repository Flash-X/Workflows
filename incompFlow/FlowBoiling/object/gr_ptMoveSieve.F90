!!****if* source/Grid/localAPI/gr_ptMoveSieve
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
!!  gr_ptMoveSieve
!!
!! SYNOPSIS
!!
!!  gr_ptMove(real(INOUT)    :: databuf(:,:),
!!            integer(IN)    :: propCount 
!!            integer(INOUT) :: localCount,
!!            integer(IN)    :: maxCount,
!!            logical(INOUT) :: moveDone)
!!                    
!!  
!! DESCRIPTION 
!!  
!!  This routine moves the particles data to their destination blocks
!!  after time integration
!!
!!  With time integration only a small fraction of particles move out
!!  of a block at any timestep. However, all particles must be examined
!!  to determine if they moved out of their curret block. With refinement
!!  all particles of one block move together to a new block. The logistics
!!  of moving the data between processors is the same in both situations.
!!  Therefore this routine can be used in both modes. 
!! 
!! ARGUMENTS 
!!
!!  databuf : List of particles. It is a 2D real array, the first dimension
!!              represents particle's properties, and second dimension is 
!!              index to particles.
!!
!! propCount : number of properties for this datastructure 
!!
!!  localCount : While coming in it contains the current 
!!               number of elements in the data structure mapped to
!!               this processor. After all the data structure 
!!               movement, the number might change, 
!!               and the new value is put back into it
!!  maxCount : This is parameter determined at runtime, 
!!             and is the maximum count of elements 
!!             that a simulation expects to have. 
!!             All the arrays  are allocated based on this number
!!  moveDone  : a logical argument to indicate whether the particles
!!              have been moved to their destination
!!
!! NOTES
!!   
!!
!! SEE ALSO
!!
!!
!!
!!
!!***


subroutine gr_ptMoveSieve(particles,localNumParticles,part_props,&
     maxParticlesPerProc, numDest, matchProp)

  integer,intent(INOUT) :: localNumParticles
  integer,intent(IN) :: part_props
  integer,intent(IN) :: maxParticlesPerProc
  integer,intent(INOUT) :: numDest
  integer,optional, intent(IN) :: matchProp

  real, dimension(part_props, maxParticlesPerProc),intent(INOUT) :: particles
end subroutine gr_ptMoveSieve

