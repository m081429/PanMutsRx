#! /usr/bin/env bash
#trap "exit 100; exit" ERR
####################
## Script Options ##
####################

#set -x

usage ()
{
cat << EOF
######################################################################
##      script to run feature counts
## Script Options:
##      -c      <configfile>      -       (REQUIRED)      required config file
##      -f      <BamfilesPath>      -       (REQUIRED)      required file with path to bam files(each line should contain <Bam file>)
##      -r      <rundir>      -       (REQUIRED)      rundir
##      -e      <email>      -       (REQUIRED)      email
##      -i      <runid>      -       (REQUIRED)      runid
##      -n      <filenumber>      -             file number to process
##      -h      - Display this usage/help text (No arg)
#############################################################################
EOF
exit
}
echo "Options specified: $@"

while getopts "c:f:r:e:i:n:h" OPTION; do
    case $OPTION in
        c) config=$OPTARG ;;
		f) fastq=$OPTARG ;;
		r) rundir=$OPTARG ;;
        e) EMAIL=$OPTARG ;;
		i) RUNID=$OPTARG ;;
		n) JOB_NUM=$OPTARG ;;
        h) usage
		exit ;;
    esac
done
shift $((OPTIND-1))

if [ -z "$config" ] || [ -z "$fastq" ] || [ -z "$rundir" ] || [ -z "$EMAIL" ] || [ -z "$RUNID" ]; then
    usage
fi

#loading the config file
source $config
source $WORKFLOW_PATH/shared_functions.sh

if [ ! -z $JOB_NUM ]
then
	SGE_TASK_ID=$JOB_NUM
fi

if [ -z $SGE_TASK_ID ]
then
	SGE_TASK_ID=1
fi

START=$(date +%s)
mkdir -p $rundir
cd $rundir
k3=$rundir
sampname=`cat $fastq|head -$SGE_TASK_ID|tail -1|sed -e 's/\t/ /g'`
countOut=`basename $sampname|sed -s 's/.bam/.counts/g'`
# if [[ "$CALLERS" =~ "STAR.2STEP.RAW.bam" ]]
# then
	# countOut=`basename $sampname|sed -s 's/2STEP.RAW.bam/gatkin.counts/g'`
# else
	# countOut=`basename $sampname|sed -s 's/RAW.bam/gatkin.counts/g'`
# fi
mkdir $countOut.tmp
$FEATURECOUNTS $FEATURECOUNTS_OPTION -o $countOut $sampname --tmpDir $countOut.tmp
rm ./$countOut.tmp/*
rmdir $countOut.tmp
check_variable $? $0 $sampname "Feature count step" $EMAIL $RUNID

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "Feature count  for $fastq took $DIFF seconds"
