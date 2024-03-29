!!****if* source/IO/IOMain/IO_setScalar
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
!!  IO_setScalar
!!
!! SYNOPSIS
!!
!!  IO_setScalar(char*(in) :: name,
!!               real/int/str/log(in) :: value) 
!!
!!
!! DESCRIPTION
!!
!!  Accessor routine that adds a named scalar value to a list
!!  of (name, scalar value) pairs, or changes the value if
!!  the name already exists in the list.
!!  The scalar lists constructed by calls to IO_setScalar
!!  will be checkpointed or written to a plotfile.
!!
!!  In FLASH4 what we mean by scalars are single value variables
!!  associated with an entire flash run.
!!  These scalars are in contrast to Grid scope variables which
!!  need to be stored at each zone of each block in the simulation.
!!  Density, pressure and temperature are examples of Grid scope 
!!  variables while simTime, dt, globalNumBlocks are single quantities
!!  associated with the entire run. 
!!
!!  Scalars of this type can be integers, reals, strings or logical
!!  values.  An example of a string scalar might be the FLASH3 run
!!  comment, name of the logfile or setup line
!!
!!  IO_setScalar is typically called by each Unit's outputScalar
!!  (ie Driver_outputScalars, Grid_outputScalars) 
!!  routines right before checkpointing or writing a plotfile.
!!  A user wishing to write a new scalar to a checkpoint file would
!!  need to call this routine
!!
!! ARGUMENTS
!!
!!  name:       name
!!  value:      name value
!!
!! 
!! NOTES
!!   
!!  Because IO_setScalar is an overloaded function a user calling
!!  the routine must include the header file IO.h
!!  
!!  (Under the hood, IO_setScalar calls IO_setScalarReal,
!!  IO_setScalarInt, IO_setScalarStr, or IO_setScalarLog and keeps a
!!  separate list for each type.)
!!
!!
!! EXAMPLE
!! 
!!  To checkpoint the simulation time, Driver_sendOutputData does
!!  call IO_setScalar("time", dr_simTime)
!!
!!***

subroutine IO_setScalarReal (name, value)

  use IO_data, only : io_scalar
  
implicit none
  character(len=*), intent(in)          :: name
  real, intent(in)                      :: value
  logical                               :: current_val = .TRUE.

  call NameValueLL_setReal(io_scalar, name, value, current_val)

  return

end subroutine IO_setScalarReal


  

  
subroutine IO_setScalarInt (name, value)
  
  use IO_data, only : io_scalar

implicit none
  character(len=*), intent(in)           :: name
  integer, intent(in)                    :: value
  logical                               :: current_val = .TRUE.

    
  call NameValueLL_setInt(io_scalar, name, value, current_val)
  
  return
  
end subroutine IO_setScalarInt



subroutine IO_setScalarStr (name, value)

  use IO_data, only : io_scalar
  
implicit none
  character(len=*),intent(in)             :: name, value
  logical                               :: current_val = .TRUE.
  
  call NameValueLL_setStr(io_scalar, name, value, current_val)

  return
  
end subroutine IO_setScalarStr






subroutine IO_setScalarLog (name, value)
  
  use IO_data, only : io_scalar

implicit none
  character(len=*),intent(in)              :: name
  logical,intent(in)                       :: value
  logical                               :: current_val = .TRUE.
  
  call NameValueLL_setLog(io_scalar, name, value, current_val)
  
  return
  
end subroutine IO_setScalarLog


