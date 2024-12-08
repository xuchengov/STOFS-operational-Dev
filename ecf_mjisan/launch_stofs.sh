#!/bin/bash

# Enable debugging and error tracking
set -x
set -e

echo "=== Starting STOFS 3D Atlantic Preparation ==="
date
echo "Current directory: $(pwd)"

# Source version file
. /lfs/h1/nos/estofs/noscrub/mansur.jisan/packages/IT-stofs.v2.1.0/versions/stofs_3d_atl/run.ver

# Base environment setup
export NET=stofs
export model=stofs
export RUN=stofs_3d_atl
export HOMEstofs=${HOMEstofs:-/lfs/h1/nos/estofs/noscrub/mansur.jisan/packages/IT-stofs.v2.1.0}
export DIR_ECF=${HOMEstofs}/ecf/3d_atl
export DIR_JOBS=${HOMEstofs}/jobs

# Path setup for COMROOT and DATAROOT
export ROOT=/lfs/h1/nos/ptmp/mansur.jisan
export COMROOT=/lfs/h1/nos/ptmp/mansur.jisan/com/stofs/v2.1
export DATAROOT=/lfs/h1/nos/ptmp/mansur.jisan/work/${RUN}

# Create and check logs directory
export LOG_DIR=${HOMEstofs}/logs/stofs_3d_atl
if [ ! -d "${LOG_DIR}" ]; then
    mkdir -p ${LOG_DIR}
fi

# Generate timestamp for log files
timestamp=$(date +%Y%m%d_%H%M%S)
echo "Using timestamp: ${timestamp}"

# Submit prep job
echo "Submitting prep job..."
PREP=$(qsub \
	   -V \
	   -l walltime=01:30:00 \
	   -l select=1:ncpus=8:mpiprocs=8 \
	   -l place=vscatter \
	   -A ESTOFS-DEV \
	   -q dev \
	   -N s3d_prep \
	   -v "HOMEstofs=$HOMEstofs,model=$model,DIR_ECF=$DIR_ECF,DIR_JOBS=$DIR_JOBS,NET=$NET,RUN=$RUN,ROOT=$ROOT,COMROOT=$COMROOT,DATAROOT=$DATAROOT" \
	   -o ${LOG_DIR}/prep_${timestamp}.out \
	   -e ${LOG_DIR}/prep_${timestamp}.err \
	   ${DIR_ECF}/jstofs_3d_atl_prep_v2.ecf)

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to submit prep job"
    exit 1
fi
echo "Prep job submitted successfully with ID: $PREP"

# Submit forecast job with dependency
echo "Submitting forecast job..."
FORECAST=$(qsub \
	       -V \
	       -W depend=afterok:${PREP} \
	       -l walltime=4:00:00 \
	       -l place=vscatter:excl,select=29:ncpus=128:mpiprocs=120:ompthreads=1 \
	       -l debug=true \
	       -A ESTOFS-DEV \
	       -q dev \
	       -N s3d_forecast \
	       -v "HOMEstofs=$HOMEstofs,model=$model,DIR_ECF=$DIR_ECF,DIR_JOBS=$DIR_JOBS,NET=$NET,RUN=$RUN,ROOT=$ROOT,COMROOT=$COMROOT,DATAROOT=$DATAROOT,NCPU_PBS=3480,MPICH_OFI_STARTUP_CONNECT=1,MPICH_COLL_SYNC=MPI_Bcast,MPICH_REDUCE_NO_SMP=1" \
	       -o ${LOG_DIR}/forecast_${timestamp}.out \
	       -e ${LOG_DIR}/forecast_${timestamp}.err \
	       ${DIR_ECF}/jstofs_3d_atl_now_forecast_v2.ecf)

if [ $? -ne 0 ]; then
    echo "ERROR: Failed to submit forecast job"
    exit 1
fi
echo "Forecast job submitted successfully with ID: $FORECAST"

# Create directory structure
mkdir -p ${COMROOT}/stofs/v2.1
mkdir -p ${DATAROOT}

# Print job information and monitoring instructions
echo "=== Job Information ==="
echo "Prep Job ID: $PREP"
echo "Forecast Job ID: $FORECAST"
echo "Log Directory: ${LOG_DIR}"
echo "Timestamp: ${timestamp}"
echo "COMROOT: ${COMROOT}"
echo "DATAROOT: ${DATAROOT}"

echo "Monitor jobs with:"
echo "qstat $PREP"
echo "qstat $FORECAST"
echo "Check logs in: ${LOG_DIR}"

echo "=== Launcher script completed ==="
date

exit 0
