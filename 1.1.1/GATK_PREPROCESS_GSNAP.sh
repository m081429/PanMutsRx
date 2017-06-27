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
##      script to run gatk preprocess splitNcigar, local realignment & base recalibration
## Script Options:
##      -c      <configfile>      -       (REQUIRED)      required config file
##      -f      <BamfilesPath>      -       (REQUIRED)      required file with fullpath to bamfile(each line should contain <BamFile>)
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
sampname=`cat $fastq|head -$SGE_TASK_ID|tail -1|sed -e 's/\t/ /g'`
START=$(date +%s)

cd $rundir
mkdir -p $rundir
# k3=$rundir
splitNCout=`basename $sampname|sed -s 's/.bam/.splitNC.realign.recaliber.bam/g'`
mv $sampname $splitNCout
$SAMTOOLS index $splitNCout
splitNCout=`basename $sampname|sed -s 's/.bam/.ba/g'`
rm $splitNCout*

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "GATK preprocess  for $sampname took $DIFF seconds"
