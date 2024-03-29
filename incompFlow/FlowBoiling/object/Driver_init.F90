!!****if* source/Driver/DriverMain/Driver_init
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
!!  Driver_init
!!
!! SYNOPSIS
!!  call Driver_init()
!!
!! DESCRIPTION
!!
!!  Perform the Driver unit initializations.
!!  Gets runtime parameters from the flash.par, or from checkpoint file
!!  if run is a restart.
!!  
!!  Initializes the simulation time, initial dt, timestep, whether 
!!  from scratch or restart.
!!  Also, verifies that the initial dt passes CFL criteria.
!!
!! ARGUMENTS
!!
!!  none
!!
!! PARAMETERS
!!  
!!   These are the runtime parameters used by the basic Driver unit.
!!   Your specific implementation may have more runtime parameters.
!!
!!   To see the default parameter values and all the runtime parameters
!!   specific to your simulation check the "setup_params" file in your
!!   object directory.
!!   You may have overwritten these values with the flash.par values
!!   for your specific run.  
!!
!!    dtinit [REAL]
!!        Initial timestep
!!    dtmax [REAL]
!!        Maximum timestep
!!    dtmin [REAL]
!!        Minimum timestep
!!    dr_dtMinContinue [REAL]
!!        Minimum timestep to continue simulation
!!    dr_dtMinBelowAction [INTEGER]
!!        Action to take when computed new timestep is below dr_dtMinContinue.
!!    nbegin [INTEGER]
!!        First timestep
!!    nend [INTEGER]
!!        Maximum number of timesteps to take
!!    restart [BOOLEAN]
!!        Is this a restart run?
!!    tinitial [REAL]
!!        Initial simulation time
!!    tmax [REAL]
!!        Maximum simulation time
!!    wall_clock_time_limit [REAL]
!!        Total wall clock time limit (seconds)
!!    tstep_change_factor [REAL]
!!        factor to allow multiplicative increase in dt until it
!!        hits the CFL condition. This lets initial dt be
!!        very conservative initially, but increase rapidly to find the
!!        the optimum value.
!!    zInitial  [REAL]
!!        The initial redshift value.  < 0 if redshift is not being used.
!!    zFinal    [REAL]
!!        The final redshift value.  If reached, the simulation ends.
!!    dr_printTStepLoc [BOOLEAN]
!!        Should the line that is written to standard output at the
!!        end of each time step show the location of a cell that
!!        imposed the most restrictive limit in the computation of
!!        the size of the next time step? 
!!    dr_shortenLastStepBeforeTMax [BOOLEAN]
!!        If TRUE, make the dt for the last time step shorter
!!        if necassary so as to avoid overshooting tmax.
!!    dr_tstepSlowStartFactor [REAL]
!!        The initial dt is set to be at most the timestep computed
!!         by CFL conditions applied to certain operators multiplied
!!         with this factor.
!!
!!
!! NOTES
!!
!! The Driver unit uses a few unit scope variables that are
!! accessible to all routines within the unit, but not to the
!! routines outside the unit. These variables begin with "dr_"
!! like, dr_globalMe or dr_dt, dr_beginStep, and are stored in FORTRAN
!! module Driver_data (in file Driver_data.F90). The other variables
!! are local to the specific routine and do not have the prefix "dr_"
!!
!!
!!***

subroutine Driver_init()
  use Driver_data
  use Driver_interface, ONLY:  Driver_putTimeStamp, Driver_abort
  use RuntimeParameters_interface, ONLY : RuntimeParameters_get
  use IO_interface, ONLY : IO_getScalar, IO_getPrevScalar
  use Logfile_interface, ONLY : Logfile_stamp

  implicit none       

#include "Simulation.h"
#include "constants.h" 
  
  character(len=40), save                :: dateStr
  integer, save :: sweepOrder
  logical :: threadBlockListBuild, threadWithinBlockBuild
  integer :: error !catch errors in IO_getPrevScalar calls

  ! Initialize for writing first checkpoint
  dr_dtNew = 0.0
  dr_dtSTS = 0.0

  ! get the parameters needed by Driver
  call RuntimeParameters_get("eachProcWritesOwnAbortLog", dr_eachProcWritesOwnAbortLog)
  call RuntimeParameters_get("dr_abortPause", dr_abortPause)
  !! hand dr_abortPause out to C routines to avoid architecture-dependent code
  call driver_abortc_set_pause(dr_abortPause)

  call RuntimeParameters_get("nend", dr_nend)

  call RuntimeParameters_get("restart", dr_restart)
  call RuntimeParameters_get("tmax", dr_tmax)
  call RuntimeParameters_get("tinitial",dr_initialSimTime)

  call RuntimeParameters_get("dtinit",dr_dtInit)
  call RuntimeParameters_get("dtmin",dr_dtMin)
  call RuntimeParameters_get("dtmax",dr_dtMax)
  call RuntimeParameters_get("dr_dtMinContinue",dr_dtMinContinue)
  call RuntimeParameters_get("dr_dtMinBelowAction",dr_dtMinBelowAction)
  call RuntimeParameters_get("tstep_change_factor", dr_tstepChangeFactor)
  call RuntimeParameters_get("dr_tstepSlowStartFactor", dr_tstepSlowStartFactor)
  call RuntimeParameters_get("wall_clock_time_limit",dr_wallClockTimeLimit)
  call RuntimeParameters_get("zInitial", dr_redshiftInitial)
  call RuntimeParameters_get("zFinal", dr_redshiftFinal)
  call RuntimeParameters_get("sweepOrder",sweepOrder)
  call RuntimeParameters_get("dr_shortenLastStepBeforeTMax",dr_shortenLastStepBeforeTMax)
  call RuntimeParameters_get("dr_printTStepLoc", dr_printTStepLoc)

!!$  call RuntimeParameters_get("useDiffuse", dr_useDiffuse)
  dr_useDiffuse=.false.
  !! Runtime parameters for super-time-stepping
  call RuntimeParameters_get("useSTS",   dr_useSTS)
!!$  call RuntimeParameters_get("useSTSforDiffusion",   dr_useSTSforDiffusion)
  if (dr_useSTS .and. dr_useSTSforDiffusion) then
     ! Check for proper use of super-time-stepping
     if (.not. dr_useDiffuse) then
        call Driver_abort("Driver_init : No diffusion used: useSTSforDiffusion should be FALSE")
     endif
  endif
  call RuntimeParameters_get("nuSTS",    dr_nuSTS)
  call RuntimeParameters_get("nstepTotalSTS", dr_nstepTotalSTS)
  call RuntimeParameters_get("allowDtSTSDominate", dr_allowDtSTSDominate)
  if ((dr_useSTSforDiffusion) .and. (.not. dr_useSTS)) then
     call Driver_abort("Driver_init : useSTS should be TRUE")
  endif
  
  call RuntimeParameters_get("drift_trunc_mantissa", dr_driftTruncMantissa)
  call RuntimeParameters_get("drift_verbose_inst", dr_driftVerboseInst)
  call RuntimeParameters_get("drift_tuples", dr_driftTuples)
  dr_driftInst = dr_globalMe
  dr_driftUnk = 0
  dr_driftBlk = 0
  
  !Check to see if redshift is being used.
  dr_useRedshift = (dr_redshiftInitial >= 0.0)
  
!!  This is not yet in use. This parameter controls timestep based
!!  upon the temperature.
!!  call RuntimeParameters_get("temp_factor", dr_tempFactor)

!! initialize a timeStamp for the run; needed in case Logfile is not included
  call current_date_time(dateStr)
  call Driver_putTimeStamp(dateStr)

  if(sweepOrder == 123) then
     dr_fSweepDir=SWEEP_XYZ
     dr_rSWeepDir=SWEEP_ZYX
  elseif(sweepOrder == 132) then
     dr_fSweepDir=SWEEP_XZY
     dr_rSWeepDir=SWEEP_YZX
  elseif(sweepOrder == 213) then
     dr_fSweepDir=SWEEP_YXZ
     dr_rSWeepDir=SWEEP_ZXY
  elseif(sweepOrder == 231) then
     dr_fSweepDir=SWEEP_YZX
     dr_rSWeepDir=SWEEP_XZY
  elseif(sweepOrder == 312) then
     dr_fSweepDir=SWEEP_ZXY
     dr_rSWeepDir=SWEEP_YXZ
  elseif(sweepOrder == 321) then
     dr_fSweepDir=SWEEP_ZYX
     dr_rSWeepDir=SWEEP_XYZ
  else
     call Driver_abort("Driver_init : invalid SweepOrder for Hydro")
  end if
  
  
  if (dr_restart) then
  
     !get values from the scalar list from the previous run
     call IO_getScalar("nstep", dr_nstep)
     call IO_getScalar("time", dr_simTime)
     call IO_getScalar("dt", dr_dt)
     call IO_getScalar("dtOld", dr_dtOld)
     call IO_getPrevScalar("dtSTS", dr_dtSTS, error)
     if(error /= NORMAL) then
        if(error == NOTFOUND) then
           dr_dtSTS = 0.0
        else
           call Driver_abort("ERROR: Error in lookup of 'dtSTS' scalar.")
        end if
     end if
     call IO_getPrevScalar("dtNew", dr_dtNew, error)
     if(error /= NORMAL) then
        if(error == NOTFOUND) then
           dr_dtNew = dr_dt
        else
           call Driver_abort("ERROR: Error in lookup of 'dtNew' scalar.")
        end if
     end if

     if(dr_useRedshift) then
        call IO_getScalar("redshift", dr_redshift)
     else
        dr_redshift = 0.0
     endif
     call IO_getPrevScalar("redshiftOld", dr_redshiftOld, error)
     if(error /= NORMAL) then
        dr_redshiftOld = dr_redshiftInitial
     end if

     dr_nbegin = dr_nstep
     dr_initialSimTime = dr_simTime

  else if (.not. dr_restart) then
     call RuntimeParameters_get("nbegin", dr_nbegin)
     dr_simTime = dr_initialSimTime
     dr_nstep = dr_nbegin
     if(dr_useRedshift) then
        dr_redshift = dr_redshiftInitial
        dr_initialSimTime = dr_simTime
     else
        dr_redshift = 0.0
     endif
     dr_redshiftOld = dr_redshiftInitial

  end if

  dr_simGeneration = 0
  dr_particlesInitialized=.false.


  call RuntimeParameters_get("threadBlockListBuild", threadBlockListBuild)
  call RuntimeParameters_get("threadDriverBlockList", dr_threadBlockList)

  call RuntimeParameters_get("threadWithinBlockBuild", threadWithinBlockBuild)
  call RuntimeParameters_get("threadDriverWithinBlock", dr_threadWithinBlock)

  if (dr_threadBlockList .and. .not. threadBlockListBuild) then
     call Logfile_stamp('WARNING! Turning off block list threading '//&
          'because Flash-X is not built appropriately','[Driver_init]')
     dr_threadBlockList = .false.
  end if
  if (dr_threadWithinBlock .and. .not. threadWithinBlockBuild) then
     call Logfile_stamp('WARNING! Turning off within-block threading '//&
          'because Flash-X is not built appropriately','[Driver_init]')
     dr_threadWithinBlock = .false.
  end if

  return
end subroutine Driver_init
