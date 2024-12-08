#!/bin/bash

echo
echo ' Begin: jstofs_3d_atl_MAIN_prep_nfcast_post.sh ' 
echo 

. /lfs/h1/nos/estofs/noscrub/mansur.jisan/packages/IT-stofs.v2.1.0/versions/stofs_3d_atl/run.ver

export model=stofs
export HOMEstofs=${HOMEstofs:-/lfs/h1/nos/estofs/noscrub/mansur.jisan/packages/IT-stofs.v2.1.0}
export DIR_ECF=${HOMEstofs}/ecf/3d_atl
export DIR_JOBS=${HOMEstofs}/jobs



# Create logs directory if it doesn't exist

export LOG_DIR=${HOMEstofs}/logs/stofs_3d_atl
mkdir -p ${LOG_DIR}

# Submit prep job and capture job ID
timestamp=$(date +%Y%m%d_%H%M%S)

# Add required PBS parameters here

PREP=$(qsub \
    -l walltime=01:30:00 \
    -l select=1:ncpus=8:mpiprocs=8 \
    -l place=vscatter \
    -A ESTOFS-DEV \
    -q dev \
    -N stofs3d_prep \
    -o $/lfs/h1/nos/estofs/noscrub/mansur.jisan/packages/IT-stofs.v2.1.0/logs/stofs_3d_atl/prep_${timestamp}.out \
    -e $/lfs/h1/nos/estofs/noscrub/mansur.jisan/packages/IT-stofs.v2.1.0/logs/stofs_3d_atl/prep_${timestamp}.err \
       ${DIR_ECF}/jstofs_3d_atl_prep_v2.ecf)


# Check if qsub was successful

#if [ $? -eq 0 ]; then
#    echo "Successfully submitted prep job with ID: $PREP"
#    echo "Log files will be in: ${LOG_DIR}"
#
#    # Wait for job to appear in queue before checking status
#    sleep 5
#
#    # Check job status
#    qstat -f $PREP > ${LOG_DIR}/jobstatus_${timestamp}.log 2>&1
#
#else
#
#    echo "Failed to submit job. Check if:"
#    echo "1. The ECF script exists: ${DIR_ECF}/jstofs_3d_atl_prep_v3.ecf"
#    echo "2. You have permission to submit jobs"
#    echo "3. The queue 'dev' is available"
#    ls -l ${DIR_ECF}/jstofs_3d_atl_prep_v2.ecf
#
#fi
#
echo
echo ' End of jstofs_3d_atl_MAIN_prep_nfcast_post.sh '
echo
