#!/bin/bash

# Enable debugging and error tracking
set -x
set -e

echo "=== Starting STOFS 3D Atlantic Preparation ==="
date
echo "Current directory: $(pwd)"

# Source version file
. /lfs/h1/nos/estofs/noscrub/mansur.jisan/packages/IT-stofs.v2.1.0/versions/stofs_3d_atl/run.ver

# Export base environment variables
export model=stofs
export HOMEstofs=${HOMEstofs:-/lfs/h1/nos/estofs/noscrub/mansur.jisan/packages/IT-stofs.v2.1.0}
export DIR_ECF=${HOMEstofs}/ecf/3d_atl
export DIR_JOBS=${HOMEstofs}/jobs

# Print environment information for debugging
echo "=== Environment Configuration ==="
echo "HOMEstofs: $HOMEstofs"
echo "model: $model"
echo "DIR_ECF: $DIR_ECF"
echo "DIR_JOBS: $DIR_JOBS"
echo "PATH: $PATH"

# Create and check logs directory
export LOG_DIR=${HOMEstofs}/logs/stofs_3d_atl
if [ ! -d "${LOG_DIR}" ]; then
    echo "Creating logs directory: ${LOG_DIR}"
    mkdir -p ${LOG_DIR}
    if [ $? -ne 0 ]; then
	echo "ERROR: Failed to create logs directory"
	exit 1
    fi
fi

# Generate timestamp for log files
timestamp=$(date +%Y%m%d_%H%M%S)
echo "Using timestamp: ${timestamp}"

# Verify prep script exists
if [ ! -f "${DIR_ECF}/jstofs_3d_atl_prep_v2.ecf" ]; then
    echo "ERROR: Prep script not found at ${DIR_ECF}/jstofs_3d_atl_prep_v2.ecf"
    exit 1
fi

# Submit prep job with environment variables
echo "Submitting prep job..."
PREP=$(qsub \
	   -V \
	   -l walltime=01:30:00 \
	   -l select=1:ncpus=8:mpiprocs=8 \
	   -l place=vscatter \
	   -A ESTOFS-DEV \
	   -q dev \
	   -N s3d_prep \
	   -v "HOMEstofs=$HOMEstofs,model=$model,DIR_ECF=$DIR_ECF,DIR_JOBS=$DIR_JOBS" \
	   -o ${LOG_DIR}/prep_${timestamp}.out \
	   -e ${LOG_DIR}/prep_${timestamp}.err \
	   ${DIR_ECF}/jstofs_3d_atl_prep_v2.ecf)

# Check job submission status
if [ $? -eq 0 ]; then
    echo "Prep job submitted successfully with ID: $PREP"

    # Monitor job logs
    echo "Log files will be available at:"
    echo "STDOUT: ${LOG_DIR}/prep_${timestamp}.out"
    echo "STDERR: ${LOG_DIR}/prep_${timestamp}.err"
else
    echo "ERROR: Failed to submit prep job"
    exit 1
fi

# Print completion message
echo "=== Launcher script completed ==="
date

exit 0
