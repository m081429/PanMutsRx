#! /usr/bin/env bash
#trap "exit 100; exit" ERR
####################
## Script Options ##
####################

set -x

usage ()
{
cat << EOF
######################################################################
##      script to run gsnap
## Script Options:
##      -c      <configfile>      -       (REQUIRED)      required config file
##      -f      <fastqfile>      -       (REQUIRED)      required file with fullpath to fastq(each line should contain <SAMPNAME> <FASTQ1> <FASTQ2>)
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
sampname=`cat $fastq|head -$SGE_TASK_ID|tail -1|sed -e 's/\t/ /g'|cut -d ' ' -f1`
inputfastq1=`cat $fastq|head -$SGE_TASK_ID|tail -1|sed -e 's/\t/ /g'|cut -d ' ' -f2`
inputfastq2=`cat $fastq|head -$SGE_TASK_ID|tail -1|sed -e 's/\t/ /g'|cut -d ' ' -f3`
START=$(date +%s)

mkdir -p $rundir
cd $rundir
if [[ $inputfastq1  =~ gz$ ]]
then
	$SH -c "$GSNAP $GSNAP_OPTION $inputfastq1 $inputfastq2 --gunzip | $SAMBLASTER $SAMBLASTER_OPTIONS|$SAMTOOLS view -Sbh - > $sampname.rg.bam"
	check_variable $? $0 $sampname "gsnap step" $EMAIL $RUNID
else
	$GSNAP $GSNAP_OPTION $inputfastq1 $inputfastq2 | $SAMBLASTER $SAMBLASTER_OPTIONS |$SAMTOOLS view -Sbh - > $sampname.rg.bam
	check_variable $? $0 $sampname "gsnap step" $EMAIL $RUNID
fi

if [ $DEBUG != "YES" ] && [ $DEBUG != "yes" ]
then
        rm $sampname.bam
fi

$SAMBAMBA sort $SAMBAMBA_PARAM --tmpdir=$rundir/ -o  $sampname.RAW.bam $sampname.rg.bam
check_variable $? $0 $sampname "Sambamba sort step" $EMAIL $RUNID
rm $sampname.rg.ba*
$SAMTOOLS index $sampname.RAW.bam
$SAMTOOLS view -b -F 4 $sampname.RAW.bam > $sampname.gatkin.bam
check_variable $? $0 $sampname "Samtools separate ummaped reads step" $EMAIL $RUNID

$SAMTOOLS  flagstat $sampname.RAW.bam > $sampname.RAW.bam.flagstat
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "gsnap aligner  for $sampname took $DIFF seconds"
