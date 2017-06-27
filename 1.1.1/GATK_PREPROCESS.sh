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
k3=$rundir
splitNCout=`basename $sampname|sed -s 's/.bam/.splitNC.bam/g'`
$JAVA -Djava.io.tmpdir=$k3  $GATK_JAVA_OPTION -jar $GATK -T SplitNCigarReads -R $REF_GENOME  -I $sampname -o $splitNCout -rf ReassignOneMappingQuality $GATK_SPLITNCIGAR_OPT -U ALLOW_N_CIGAR_READS
exit_code=$?
Allow_n_cigar=""

if [[ $sampname =~ "GSNAP.gatkin.bam" ]] && [ $exit_code -eq 1 ]
then
        rm $splitNCout
		indexfile=`echo $splitNCout|sed -e 's/bam/bai/g'`
		rm $indexfile
		cp $sampname $splitNCout
		$SAMTOOLS index $splitNCout
		Allow_n_cigar="-U ALLOW_N_CIGAR_READS"
else
		check_variable $exit_code $0 $sampname "GATK preprocess splitNCigar step" $EMAIL $RUNID $rundir/$splitNCout
fi

     

splitNCoutInt=`echo $splitNCout|sed -s 's/bam/intervals/g'`
$JAVA -Djava.io.tmpdir=$k3  $GATK_JAVA_OPTION -jar $GATK -T RealignerTargetCreator -R $REF_GENOME -I $splitNCout -o $splitNCoutInt $Allow_n_cigar
check_variable $? $0 $splitNCout "GATK preprocess RealignerTargetCreator step" $EMAIL $RUNID $rundir/$splitNCoutInt

realignOut=`echo $splitNCoutInt|sed -s 's/intervals/realign.bam/g'`
$JAVA -Djava.io.tmpdir=$k3  $GATK_JAVA_OPTION -jar $GATK -T IndelRealigner -R $REF_GENOME -I $splitNCout -targetIntervals $splitNCoutInt -o $realignOut $Allow_n_cigar
check_variable $? $0 $splitNCout "GATK preprocess IndelRealigner step" $EMAIL $RUNID $rundir/$realignOut

if [ $DEBUG != "YES" ] && [ $DEBUG != "yes" ]
then
		rm $splitNCout $splitNCoutInt
		tmp=`echo $splitNCout|sed -s 's/.bam/.bai/g'`
		rm $tmp
fi

recal_data=`echo $splitNCoutInt|sed -s 's/intervals/recal_data.table/g'`
$JAVA -Djava.io.tmpdir=$k3  $GATK_JAVA_OPTION -jar $GATK -T BaseRecalibrator -R $REF_GENOME -I $realignOut  $GATK_BASE_RECALIBRATION_KNOWNSITES -o $recal_data $Allow_n_cigar
check_variable $? $0 $realignOut "GATK preprocess BaseRecalibrator step" $EMAIL $RUNID $rundir/$recal_data
printReadsOut=`echo $realignOut|sed -s 's/.bam/.recaliber.bam/g'`
$JAVA -Djava.io.tmpdir=$k3  $GATK_JAVA_OPTION -jar $GATK -T PrintReads -R $REF_GENOME -I $realignOut -BQSR $recal_data -o $printReadsOut $Allow_n_cigar
check_variable $? $0 $realignOut "GATK preprocess PrintReads step" $EMAIL $RUNID $rundir/$printReadsOut

if [ $DEBUG != "YES" ] && [ $DEBUG != "yes" ]
then
        rm $realignOut
		tmp=`echo $realignOut|sed -s 's/.bam/.bai/g'`
		rm $tmp
		rm $recal_data
fi

if [ $DEBUG != "YES" ] && [ $DEBUG != "yes" ]
then
	#combining the unmapped reads to other chr bam file
	#original=`basename $sampname|sed -s 's/gatkin.bam/rg.bam/g'`
	rm $sampname $sampname.bai
	
	#$SAMBAMBA sort $SAMBAMBA_PARAM --tmpdir=$rundir/ -o  $sampname $original
	#check_variable $? $0 $original "sambamba sort step" $EMAIL $RUNID
	#rm $original $original.bai
	
fi   

END=$(date +%s)
DIFF=$(( $END - $START ))
echo "GATK preprocess  for $sampname took $DIFF seconds"
