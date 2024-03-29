!!****if* source/Grid/GridMain/Grid_formatNonRep
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
!!  Grid_formatNonRep
!!
!!
!! SYNOPSIS
!!
!!  Grid_formatNonRep(integer(IN) :: nonrep,
!!                    integer(IN) :: idx,
!!                    character(len=*)(OUT) :: str)
!!
!!
!! DESCRIPTION
!!
!!  Given a nonreplicated variable array id and index into that array, returns a string name suitable for IO
!!
!!
!! ARGUMENTS
!!  
!!   nonrep - array id
!!   idx - index into array
!!   str - receives string name
!!
!!***
subroutine Grid_formatNonRep(nonrep, idx, str)
    implicit none
#include "Simulation.h"
#include "constants.h"
    integer, intent(in) :: nonrep, idx
    character(*), intent(out) :: str
    character(len=MAX_STRING_LENGTH) :: temp_str
    
    character(*), parameter :: namef_flat = NONREP_NAMEF_FLAT_LWR
    integer, parameter :: namef_start(NONREP_COUNT+1) = NONREP_NAMEF_START

    integer :: i, d, slen

    temp_str = namef_flat(namef_start(nonrep):namef_start(nonrep+1)-1)
    slen = namef_start(nonrep+1) - namef_start(nonrep)
    d = idx
    do i = slen, 1, -1
        if(temp_str(i:i) .eq. "?") then
            temp_str(i:i) = char(ichar("0") + mod(d, 10))
            d = d/10
        end if
    end do

    str = temp_str

end subroutine
