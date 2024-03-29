!!****ih* source/IO/IOMain/hdf5/io_intfTypesModule
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
!!  io_intfTypesModule
!!
!! SYNOPSIS
!!  use io_intfTypesModule, ONLY : io_fileID_t
!!
!! DESCRIPTION
!!
!!  This is an auxiliary module for Fortran declarations
!!  of types that appear in various interfaces.
!!
!! EXAMPLE
!!
!!   subroutine io_blah(...,fileID,...)
!!   ...
!!   use io_intfTypesModule, ONLY : io_fileID_t
!!   ...
!!   INTEGER(KIND=io_fileID_t),INTENT(IN) :: fileID
!!   ...
!!
!! NOTES
!!
!!  Some type parameters for handles that are passed
!!  between routines may vary depending on which IO
!!  implementation is compiled in. Using the appropriate
!!  variant of this module is a way to use call interfaces
!!  that are identical between unit implementations except
!!  for such type details.
!!***

#include "Simulation.h"

#ifdef HAVE_HDF5_FORTRAN
#define IO_USE_HDF5_MOD HAVE_HDF5_FORTRAN
#else
#ifdef FLASH_HAVE_HDF5_MOD
#define IO_USE_HDF5_MOD FLASH_HAVE_HDF5_MOD
#endif
#endif

#ifndef IO_USE_HDF5_MOD
#define IO_USE_HDF5_MOD 0
#endif

#if IO_USE_HDF5_MOD == 0
#  if (H5_VERS_MAJOR == 1 && H5_VERS_MINOR < 10)
#    define FLASH_IO_FILEID_T kind(1)
#  else
#    define FLASH_IO_FILEID_T selected_int_kind(18)
#  endif
#else
#  define FLASH_IO_FILEID_T HID_T
#endif


module io_intfTypesModule

#if (IO_USE_HDF5_MOD != 0)
  use HDF5, ONLY : HID_T
#endif

  implicit none

  integer,parameter :: io_fileID_t = FLASH_IO_FILEID_T

end module io_intfTypesModule
