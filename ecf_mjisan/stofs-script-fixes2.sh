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

# Add required PBS parameters for prep job
echo "Submitting prep job..."
PREP=$(qsub \
	   -l walltime=01:30:00 \
	   -l select=1:ncpus=8:mpiprocs=8 \
	   -l place=vscatter \
	   -A ESTOFS-DEV \
	   -q dev \
	   -N s3d_prep \
	   -o ${LOG_DIR}/prep_${timestamp}.out \
	   -e ${LOG_DIR}/prep_${timestamp}.err \
	   ${DIR_ECF}/jstofs_3d_atl_prep_v2.ecf)

exit
# Check if prep job submission was successful
if [ $? -eq 0 ]; then
    echo "Successfully submitted prep job with ID: $PREP"
    echo "Prep log files will be in: ${LOG_DIR}"

    # Submit forecast job with dependency on prep job
    echo "Submitting forecast job..."
    FORECAST=$(qsub \
		   -l walltime=4:00:00 \
		   -l place=vscatter:excl,select=29:ncpus=128:mpiprocs=120:ompthreads=1 \
		   -l debug=true \
		   -A ESTOFS-DEV \
		   -q dev \
		   -N s3d_nfcast \
		   -W depend=afterok:${PREP} \
		   -o ${LOG_DIR}/forecast_${timestamp}.out \
		   -e ${LOG_DIR}/forecast_${timestamp}.err \
		   ${DIR_ECF}/jstofs_3d_atl_now_forecast_v2.ecf)

    if [ $? -eq 0 ]; then
	echo "Successfully submitted forecast job with ID: $FORECAST"
	echo "Forecast log files will be in: ${LOG_DIR}"

	# Wait for jobs to appear in queue before checking status
	sleep 5

	# Check job statuses
	echo "Writing job status information..."
	qstat -f $PREP > ${LOG_DIR}/prep_jobstatus_${timestamp}.log 2>&1
	qstat -f $FORECAST > ${LOG_DIR}/forecast_jobstatus_${timestamp}.log 2>&1
    else
	echo "Failed to submit forecast job"
    fi
else
    echo "Failed to submit prep job. Check if:"
    echo "1. The ECF script exists: ${DIR_ECF}/jstofs_3d_atl_prep_v2.ecf"
    echo "2. You have permission to submit jobs"
    echo "3. The queue 'dev' is available"
    ls -l ${DIR_ECF}/jstofs_3d_atl_prep_v2.ecf
fi

echo
echo ' End of jstofs_3d_atl_MAIN_prep_nfcast_post.sh '
echo
