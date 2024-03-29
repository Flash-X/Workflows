!!****if* source/RuntimeParameters/RuntimeParametersMain/rp_rules
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
!!  rp_rulesInt
!!
!! SYNOPSIS
!!
!!  rp_rulesInt(char*(in) :: name,
!!                              integer(in) :: numValues,
!!                              integer(:),intent(in) :: minValues,
!!                              integer(:),intent(in) :: maxValues)
!!
!! DESCRIPTION
!!
!! Sets rules for given parameter
!!
!! ARGUMENTS
!!
!!    name--         name of parameter
!!    numValues--    number of valid values
!!    minValues--    array of given size, provides minimum of valid values
!!    maxValues--    array of given size, provides maximum of valid values
!!
!! EXAMPLE
!!
!!
!!***

subroutine rp_rulesInt (name, numValues, minValues, maxValues)

  use RuntimeParameters_data, only : parameter
 
implicit none
  character(len=*), intent(in)          :: name
  integer, intent(in)                   :: numValues
  integer, dimension(numValues),intent(in) :: minValues, maxValues

  call nameValueLL_rulesInt(parameter, name, numValues, minValues, maxValues)

  return

end subroutine rp_rulesInt

!!****if* source/RuntimeParameters/RuntimeParametersMain/rp_rulesReal
!!
!! NAME
!!  rp_rulesReal
!!
!! SYNOPSIS
!!
!!  rp_rulesReal(char*(in) :: name,
!!                              integer(in) :: numValues,
!!                              real(:),intent(in) :: minValues,
!!                              real(:),intent(in) :: maxValues)
!!
!! DESCRIPTION
!!
!! Sets rules for given parameter
!!
!! ARGUMENTS
!!
!! name:       name
!! numValues:      name value
!!
!! EXAMPLE
!!
!!
!!***

subroutine rp_rulesReal (name, numValues, minValues, maxValues)

  use RuntimeParameters_data, only : parameter
  
implicit none
  character(len=*), intent(in)          :: name
  integer, intent(in)                   :: numValues
  real, dimension(numValues),intent(in) :: minValues, maxValues

  call nameValueLL_rulesReal(parameter, name, numValues, minValues, maxValues)

  return

end subroutine rp_rulesReal

!!****if* source/RuntimeParameters/RuntimeParametersMain/rp_rulesStr
!!
!! NAME
!!  rp_rulesReal
!!
!! SYNOPSIS
!!
!!  rp_rulesStr(char*(in) :: name,
!!                             integer(in) :: numValues,
!!                             character(len=*), intent(in) :: validValues)
!!
!! DESCRIPTION
!!
!! Sets rules for given parameter
!!
!! ARGUMENTS
!!
!! name:       name
!! numValues:      name value
!!
!! EXAMPLE
!!
!!
!!***

subroutine rp_rulesStr (name, numValues, validValues)

  use RuntimeParameters_data, only : parameter
  
implicit none
  character(len=*), intent(in)          :: name
  integer, intent(in)                   :: numValues
  character(len=*), dimension(numValues), intent(in)          :: validValues

  call nameValueLL_rulesStr(parameter, name, numValues, validValues)

  return

end subroutine rp_rulesStr

