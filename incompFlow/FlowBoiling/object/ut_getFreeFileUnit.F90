!!****if* source/flashUtilities/general/ut_getFreeFileUnit
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
!!  ut_getFreeFileUnit
!!
!! SYNOPSIS
!!
!!   ut_getFreeFileUnit ()
!!
!! DESCRIPTION
!!
!!  Integer function, which returns a free unit number for file handling.
!!  It loops over a set of permissible integer values and checks availability
!!  using the inquire command.
!!
!! ARGUMENTS
!!
!!   none
!!
!!***
integer function ut_getFreeFileUnit ()

  use Driver_interface, ONLY : Driver_abort

  implicit none
  
  logical :: connected
  integer :: number
!
!
!   ...Get a free unit number within range 7-999.
!
!
  ut_getFreeFileUnit = 0

  do number = 7,999
     inquire (UNIT = number, OPENED = connected)
     if (.not.connected) then
          ut_getFreeFileUnit = number
          exit
     end if
  end do
!
!
!   ...Abort, if none found.
!
!
  if (ut_getFreeFileUnit == 0) then
      call Driver_abort ('[ut_getFreeFileUnit] ERROR: no free unit number < 1000 found')
  end if
!
!
!   ...Ready! 
!
!
  return
end function ut_getFreeFileUnit
