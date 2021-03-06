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
##      script to run gatk caller
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

sampname=`cat $fastq|head -$SGE_TASK_ID|tail -1|sed -e 's/\t/ /g'`
START=$(date +%s)
mkdir -p $rundir
cd $rundir
k3=$rundir
gatkOut=`basename $sampname|sed -s 's/.bam/.GATK.raw.vcf/g'`
$JAVA -Djava.io.tmpdir=$k3  $GATK_JAVA_OPTION -jar $GATK -T HaplotypeCaller -R $REF_GENOME -I $sampname $GATK_HAPLOTYPE_CALLER_OPTION -o $gatkOut -U ALLOW_N_CIGAR_READS
check_variable $? $0 $sampname "GATK HaplotypeCaller step" $EMAIL $RUNID
gatkFilOut=`echo $gatkOut|sed -s 's/.GATK.raw.vcf/.GATK.Filtered.vcf/g'`
$JAVA -Djava.io.tmpdir=$k3  $GATK_JAVA_OPTION -jar $GATK -T VariantFiltration -R $REF_GENOME -V $gatkOut -window 35 -cluster 3 -filterName FS -filter "FS > 30.0" -filterName QD -filter "QD < 2.0" -o $gatkFilOut
check_variable $? $0 $sampname "GATK Hard FIltering step" $EMAIL $RUNID
rm $gatkOut
if [ "$ANNOVAR_OPTION" != "NA" ] && [ "$ANNOVAR_OPTION" != "na" ] 
then
	annovar $config $rundir $gatkFilOut
	check_variable $? $0 $sampname "GATK ANNOVAR step" $EMAIL $RUNID
	#if [ "$GENE_FILTER" != "NA" ] && [ "$GENE_FILTER" != "na" ] 
	#then
	#	genefilin=`echo $gatkOut|sed -s 's/.GATK.raw.vcf/.GATK.Filtered.ANNOVAR.vcf/g'`
	#	genefilout=`echo $gatkOut|sed -s 's/.GATK.raw.vcf/.GATK.Filtered.ANNOVAR.GENE_FILTER.vcf/g'`
	#	$PYTHON $WORKFLOW_PATH/Gene_Filter.py -g $GENE_FILTER -i $genefilin -o $genefilout
	#	check_variable $? $0 $sampname "GENE FILTER GATK ANNOVAR step" $EMAIL $RUNID
	#fi
fi



END=$(date +%s)
DIFF=$(( $END - $START ))
echo "GATK Haplotype Caller  for $sampname took $DIFF seconds"
