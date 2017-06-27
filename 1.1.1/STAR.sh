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
##      script to run star
## Script Options:
##      -c      <configfile>      -       (REQUIRED)      required config file
##      -f      <fastqfile>      -       (REQUIRED)      required file with path to fastq(each line should contain <FASTQ1> <FASTQ2>)
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
mkdir $rundir/$sampname.Starref
cd $rundir/$sampname.Starref

mkdir $rundir/$sampname.process_dir_pass2
cd $rundir/$sampname.process_dir_pass2

if [[ $inputfastq1  =~ gz$ ]]
then
	$STAR --genomeDir $STAR_REF --readFilesIn $inputfastq1 $inputfastq2  $STAR_OPTION_STEP2  --readFilesCommand zcat --outSAMunmapped Within
	check_variable $? $0 $sampname "star step2" $EMAIL $RUNID
else
	$STAR --genomeDir $STAR_REF --readFilesIn $inputfastq1 $inputfastq2 $STAR_OPTION_STEP2 --outSAMunmapped Within
	check_variable $? $0 $sampname "star step2" $EMAIL $RUNID
fi

if [ $DEBUG != "YES" ] && [ $DEBUG != "yes" ]
then
        rm $rundir/$sampname.process_dir_pass2/_STAR*/*  
		rmdir $rundir/$sampname.process_dir_pass2/_STAR*  
fi

k3=$rundir/
cd $rundir
# $SAMBAMBA sort $SAMBAMBA_PARAM -n --tmpdir=$rundir/ -o $rundir/$sampname.process_dir_pass2/Aligned.out.sortedByName.out.bam $rundir/$sampname.process_dir_pass2/Aligned.out.bam
$SAMBAMBA sort $SAMBAMBA_PARAM --tmpdir=$rundir/ -o $rundir/$sampname.process_dir_pass2/Aligned.out.sortedByName.out.bam $rundir/$sampname.process_dir_pass2/Aligned.out.bam
if [ $DEBUG != "YES" ] && [ $DEBUG != "yes" ]
then
        rm $rundir/$sampname.process_dir_pass2/Aligned.out.bam 
fi
# $SAMTOOLS view -h $rundir/$sampname.process_dir_pass2/Aligned.out.sortedByName.out.bam|$SAMBLASTER $SAMBLASTER_OPTIONS|$SAMTOOLS view -Sbh - > $sampname.bam
$JAVA -Djava.io.tmpdir=$k3  $GSNAP_JAVA_OPTION -jar $PICARD MarkDuplicates I=$rundir/$sampname.process_dir_pass2/Aligned.out.sortedByName.out.bam O=$sampname.bam  METRICS_FILE=$sampname.dup.metrics.txt
if [ $DEBUG != "YES" ] && [ $DEBUG != "yes" ]
then
        rm  $rundir/$sampname.process_dir_pass2/Aligned.out.sortedByName.out.bam  
fi

$JAVA -Djava.io.tmpdir=$k3  $GSNAP_JAVA_OPTION -jar $PICARD AddOrReplaceReadGroups I=$sampname.bam O=$sampname.2STEP.RAW.bam $PICARD_ARG_OPTION TMP_DIR=$k3
check_variable $? $0 $sampname "Picard AddorReplace step" $EMAIL $RUNID
$SAMTOOLS index $sampname.2STEP.RAW.bam
check_variable $? $0 $sampname "samtools index" $EMAIL $RUNID
if [ $DEBUG != "YES" ] && [ $DEBUG != "yes" ]
then
        rm $sampname.bam
fi

$SAMTOOLS view -b -F 4 $sampname.2STEP.RAW.bam > $sampname.gatkin.bam
check_variable $? $0 $sampname "Samtools separate ummaped reads step" $EMAIL $RUNID

$SAMTOOLS index $sampname.gatkin.bam

$SAMTOOLS  flagstat $sampname.2STEP.RAW.bam > $sampname.2STEP.RAW.bam.flagstat
END=$(date +%s)
DIFF=$(( $END - $START ))
echo "star aligner  for $sampname took $DIFF seconds"
