!!****f* source/Multispecies/Multispecies_getPropertyVector
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
!!  Multispecies_getPropertyVector
!!
!! 
!! SYNOPSIS
!!
!!  call Multispecies_getPropertyVector(integer(in) :: property,
!!                                      real(out),dimension(:) :: values(NSPECIES) )
!!
!! DESCRIPTION
!!
!!  Returns the values of a property of the species name in value.
!!  The name is an integer because it is defined in Simulation.h based on Config data.
!!  
!!  description    property(defined as integer in Multispecies.h)
!!  --------------------------------------------------------------
!!  numTotal        A         Total number of protons and neutrons in nucleus
!!  numPositive     Z         Atomic number; number of protons in nucleus
!!  numNeutral      N         Number of neutrons
!!  numNegative     E         Number of electrons
!!  bindingEnergy   EB        Binding energy
!!  adiabatic index GAMMA     Ratio of heat capacities: Cp / Cv
!!  
!!  
!!  ARGUMENTS
!!    property - name of property define as an integer
!!    values - vector of values of the returned property
!!
!!  NOTES
!!
!!  Species properties are normally set in Simulation_initSpecies.
!!  The simulation's Config file defines the number and names of species.
!!
!!***  

subroutine Multispecies_getPropertyVector(property, values)

  implicit none

  integer, intent(in)       :: property
  real, intent(out)         :: values(:)


  values(:) = 0.0

end subroutine Multispecies_getPropertyVector

