!!***if* source/IO/localAPI/io_ptInit
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
!!  io_ptInit
!!
!! SYNOPSIS
!!
!!  io_ptInit()
!!
!! DESCRIPTION
!!
!!  Perform IOParticles initialization
!!
!!
!!  The IOParticles unit uses a number of runtime parameters to determine
!!  if, when, and how various particle output files need to be written.
!!
!!  To determine exactly which runtime parameters control these
!!  files, please check the Config file in IO/IOParticles or the
!!  setup_params file in the object directory.
!!
!!
!! 
!! ARGUMENTS
!!
!!
!! PARAMETERS
!!  
!!   These are the runtime parameters used by IOParticles sub unit.
!!
!!   To see the default parameter values and all the runtime parameters
!!   specific to your simulation, check the "setup_params" file in your
!!   object directory.
!!   You might have overwritten these values with the flash.par values
!!   for your specific run.
!!
!!    particleFileIntervalStep [INTEGER]
!!        write a particle file after this many steps
!!    particleFileIntervalTime [REAL]
!!        Write a particle plot after this much time
!!    particleFileNumber [INTEGER]
!!        Initial particle plot file number
!!
!!***

subroutine io_ptInit()

implicit none

end subroutine io_ptInit
